# Phase 5 — AI Integration

**App:** MingleGrid Demo (built on Open Demo Starter v2.0)  
**Goal:** Wire up Gemini, build the full charter display, and implement the Turbo Frame generate flow. After this phase the app is functionally complete.  
**Spec reference:** [`minglegrid-demo-spec.md`](minglegrid-demo-spec.md) — Sections 5, 6, 7, 8  
**Depends on:** Phase 3 (routes + support groups CRUD), Phase 4 (CharterParser + fixture)  
**Next phase:** [phase_6_seeds.md](phase_6_seeds.md)

**Before starting, read:**
- `docs/turbo-stimulus-patterns.md` — **critical**: always `turbo_stream.update`, never `replace`; Turbo Frame redirect flow
- `docs/ai-templates.md` — GeminiService.generate call signature, error classes, and the 9-step flow
- `docs/ai-guardrails.md` — AiGatekeeper, AiBudgetChecker, LlmRequest, and how errors surface
- `CLAUDE.md` — Gemini model note: use `gemini-2.5-flash` (NOT `gemini-2.0-flash` — deprecated for new API keys)

---

## Tasks

### 5.1 — Seed the AI template

Add to `db/seeds.rb` using `find_or_create_by!`:

```ruby
AiTemplate.find_or_create_by!(name: "minglegrid_charter_v1") do |t|
  t.description = "Generates a S.A.F.E. peer support group charter, four-session launch sequence, and two facilitator boundary reminders."
  t.model       = "gemini-2.5-flash"
  t.max_output_tokens = 3000
  t.temperature = 0.6

  t.system_prompt = <<~PROMPT.strip
    You are a peer support group design assistant trained on the S.A.F.E. framework
    (Structure, Accountability, Formation, Evolution). You produce charters and launch
    sequences for community-led peer support groups in faith, nonprofit, workplace,
    and online settings.

    You are NOT a clinician, therapist, or crisis professional. You do not provide
    medical advice, diagnose conditions, recommend treatment, or write content for
    groups whose primary purpose is acute crisis intervention. If the user's
    description suggests a clinical setting (active suicidality, acute psychiatric
    care, court-ordered treatment, medication management), respond with a single JSON
    object: {"refusal": "This brief describes a clinical context that requires a
    licensed professional to design. This tool is for peer support, not clinical
    care."} and produce no charter.

    For every other request, you return a single valid JSON object matching this
    schema exactly:

    {
      "purpose_statement": "string, 2 to 4 sentences",
      "meeting_structure": "string, 3 to 5 sentences describing the regular meeting flow",
      "member_commitments": "string, 3 to 4 sentences describing what members agree to",
      "agreements": ["string", "string", "string", "string"],
      "sessions": [
        {
          "session_number": 1,
          "title": "string",
          "check_in_format": "string",
          "discussion_topic": "string",
          "activity": "string",
          "closing_ritual": "string"
        },
        { "session_number": 2, ... },
        { "session_number": 3, ... },
        { "session_number": 4, ... }
      ],
      "boundary_reminders": ["string", "string"]
    }

    REQUIRED CONSTRAINTS (the response is invalid without all of them):
    - agreements MUST contain 4 or 5 entries covering privacy, sharing limits,
      participation expectations, and respectful disagreement
    - sessions MUST contain exactly 4 entries with session_number 1, 2, 3, 4
    - The four sessions MUST follow the S.A.F.E. Formation arc:
      Session 1 trust building, Session 2 expectation setting, Session 3 deepening,
      Session 4 pattern review and forward planning
    - boundary_reminders MUST contain exactly 2 entries. Each is a short phrase
      (under 30 words) the facilitator can say verbatim when conversation drifts
      into clinical, legal, or crisis territory peer support cannot hold
    - All output text is in plain prose. No markdown, no headings, no bullet
      characters inside string values

    Return only the JSON object. No preamble, no postamble, no code fences.
  PROMPT

  t.user_prompt_template = <<~PROMPT.strip
    Design a S.A.F.E. peer support group charter and four-session launch sequence
    for the following group:

    Group purpose: {{purpose}}

    Target demographics: {{target_demographics}}

    Meeting cadence: {{meeting_cadence}}

    Session length: {{session_length_minutes}} minutes

    Host organization type: {{organization_type}}

    Produce the JSON object described in your instructions. Calibrate the tone,
    activity choices, and check-in formats to the host organization type and the
    sensitivity of the group's purpose. The two boundary reminders must reflect
    specific risks adjacent to this group's purpose, not generic peer-support
    caveats.
  PROMPT

  t.notes = <<~NOTES.strip
    Use gemini-2.5-flash (not gemini-2.0-flash — deprecated for new API keys).
    Temperature 0.6 produces consistent JSON structure and conservative recommendations.
    Max tokens 3000 — testing showed 2000 occasionally truncates Session 4.
    Watch for: drift toward clinical language in agreements; Session 3 going too deep;
    boundary reminders being too similar. If reminders are paraphrases of each other, regenerate.
  NOTES
end
```

Run `rails db:seed` after adding. Verify the template appears in `/admin/ai_templates`.

### 5.2 — `app/controllers/charters_controller.rb`

```ruby
class ChartersController < ApplicationController
  before_action :set_support_group

  rate_limit to: 10, within: 1.minute, only: [:create, :regenerate],
             with: -> { redirect_to support_group_path(@support_group), alert: "Please wait before generating again." }

  def create
    generate_charter
  end

  def regenerate
    @support_group.group_charter&.destroy
    generate_charter
  end

  def print
    @charter = @support_group.group_charter
    return render file: Rails.public_path.join("404.html"), status: :not_found if @charter.nil?
    render layout: "print"
  end

  private

  def set_support_group
    @support_group = current_user.support_groups.find(params[:support_group_id])
  end

  def generate_charter
    raw = GeminiService.generate(
      template: "minglegrid_charter_v1",
      variables: {
        purpose:                @support_group.purpose,
        target_demographics:    @support_group.target_demographics.presence || "not specified",
        meeting_cadence:        @support_group.meeting_cadence,
        session_length_minutes: @support_group.session_length_minutes,
        organization_type:      @support_group.organization_type.humanize.downcase
      }
    )

    data = CharterParser.new(raw).parse!
    persist_charter(data, raw)
    redirect_to support_group_path(@support_group), notice: "Charter generated."

  rescue CharterParser::ParseError => e
    if e.refusal?
      flash_error(e.message)
    else
      flash_error("The AI response couldn't be parsed. Try regenerating.")
    end
    render_charter_error

  rescue GeminiService::GatekeeperError
    flash_error("Your group description triggered a safety check. Try shortening it or removing copied content.")
    render_charter_error

  rescue GeminiService::BudgetExceededError
    flash_error("Daily AI limit reached. Try again tomorrow.")
    render_charter_error

  rescue GeminiService::TimeoutError
    flash_error("Gemini took too long. Click retry.")
    render_charter_error

  rescue GeminiService::GeminiError
    flash_error("Something went wrong generating your charter. Please try again.")
    render_charter_error
  end

  def persist_charter(data, raw)
    ActiveRecord::Base.transaction do
      charter = @support_group.create_group_charter!(
        purpose_statement:  data["purpose_statement"],
        meeting_structure:  data["meeting_structure"],
        member_commitments: data["member_commitments"],
        agreements:         data["agreements"].to_json,
        boundary_reminders: data["boundary_reminders"].to_json,
        gemini_raw:         raw,
        generated_at:       Time.current
      )
      data["sessions"].each do |s|
        charter.launch_sessions.create!(
          session_number:   s["session_number"],
          title:            s["title"],
          check_in_format:  s["check_in_format"],
          discussion_topic: s["discussion_topic"],
          activity:         s["activity"],
          closing_ritual:   s["closing_ritual"]
        )
      end
    end
  end

  def flash_error(message)
    flash.now[:alert] = message
  end

  def render_charter_error
    @charter  = @support_group.group_charter
    @sessions = @charter&.launch_sessions&.order(:session_number)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("charter-region",
          partial: "charters/generate_cta",
          locals: { support_group: @support_group, error: flash[:alert] })
      end
      format.html { redirect_to support_group_path(@support_group), alert: flash[:alert] }
    end
  end
end
```

**Turbo Frame flow:**
- The "Generate charter" button posts to `support_group_charter_path` inside a `turbo_frame_tag "charter-region"`.
- On success: `redirect_to` → Turbo follows the redirect → show page re-renders → the frame swaps the charter content region automatically.
- On error: render a Turbo Stream `update` (never `replace`) targeting `"charter-region"` with the generate CTA partial and the error message inline.

### 5.3 — `app/views/layouts/print.html.erb`

```erb
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= ENV.fetch("APP_NAME", "MingleGrid Demo") %> — Charter</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <%= stylesheet_link_tag "application" %>
    <%= stylesheet_link_tag "minglegrid" %>
  </head>
  <body class="bg-white text-dark">
    <%= yield %>
  </body>
</html>
```

No navbar, no footer. White background overrides dark mode.

### 5.4 — `app/views/charters/_generate_cta.html.erb`

Replace the Phase 3 stub with the real implementation:

```erb
<div class="card">
  <div class="card-body text-center py-5">
    <% if local_assigns[:error].present? %>
      <div class="alert alert-danger mb-4"><%= error %></div>
    <% end %>
    <h4>Your charter is ready to generate</h4>
    <p class="text-muted">
      Gemini will return a group charter (purpose, structure, commitments, and agreements),
      a four-session S.A.F.E. launch sequence, and two boundary reminders for your facilitator.
    </p>
    <%= button_to "Generate charter",
        support_group_charter_path(support_group),
        class: "btn bg-accent btn-lg mt-2",
        data: { turbo_submits_with: "Generating…" } %>
  </div>
</div>
```

### 5.5 — `app/views/charters/_charter_card.html.erb`

```erb
<div class="card mb-3">
  <div class="card-body">
    <h4>Charter</h4>

    <h6 class="mt-3">Purpose</h6>
    <p><%= charter.purpose_statement %></p>

    <h6>Meeting structure</h6>
    <p><%= charter.meeting_structure %></p>

    <h6>Member commitments</h6>
    <p><%= charter.member_commitments %></p>

    <h6>Group agreements</h6>
    <ol>
      <% charter.agreements_list.each do |agreement| %>
        <li><%= agreement %></li>
      <% end %>
    </ol>
  </div>
  <div class="card-footer d-flex gap-2">
    <%= link_to "Print charter", print_support_group_charter_path(support_group),
        class: "btn btn-sm btn-outline-secondary", target: "_blank" %>
    <%= button_to "Regenerate",
        regenerate_support_group_charter_path(support_group),
        class: "btn btn-sm btn-outline-warning",
        data: { turbo_confirm: "This will replace the current charter. Continue?" } %>
  </div>
</div>
```

### 5.6 — `app/views/charters/_session_card.html.erb`

```erb
<div class="card session-card">
  <div class="card-header">
    <span class="session-badge me-2">Session <%= session.session_number %></span>
    <button class="btn btn-link p-0 text-decoration-none text-reset"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#session-<%= session.session_number %>-collapse">
      <%= session.title %>
    </button>
  </div>
  <div class="collapse" id="session-<%= session.session_number %>-collapse">
    <div class="card-body small">
      <p><strong>Check-in:</strong> <%= session.check_in_format %></p>
      <p><strong>Discussion:</strong> <%= session.discussion_topic %></p>
      <p><strong>Activity:</strong> <%= session.activity %></p>
      <p><strong>Closing:</strong> <%= session.closing_ritual %></p>
    </div>
  </div>
</div>
```

### 5.7 — `app/views/charters/_boundary_panel.html.erb`

```erb
<div class="boundary-panel">
  <h6>Boundary reminders</h6>
  <p class="text-muted small mb-3">Use these if conversation drifts beyond what peer support can hold.</p>
  <% charter.boundary_reminders_list.each do |reminder| %>
    <p class="reminder-text"><%= reminder %></p>
  <% end %>
</div>
```

### 5.8 — `app/views/charters/print.html.erb`

```erb
<div class="container py-4">
  <h1><%= @support_group.name %></h1>
  <p class="text-muted"><%= @support_group.organization_type.humanize %> · <%= @support_group.meeting_cadence.humanize %> · <%= @support_group.session_length_minutes %> min</p>

  <h4>Purpose</h4>
  <p><%= @charter.purpose_statement %></p>

  <h4>Meeting structure</h4>
  <p><%= @charter.meeting_structure %></p>

  <h4>Member commitments</h4>
  <p><%= @charter.member_commitments %></p>

  <h4>Group agreements</h4>
  <ol>
    <% @charter.agreements_list.each do |a| %>
      <li><%= a %></li>
    <% end %>
  </ol>

  <h4>Launch sessions</h4>
  <% @charter.launch_sessions.order(:session_number).each do |s| %>
    <div class="session-card mb-3 p-3 border rounded">
      <strong>Session <%= s.session_number %>: <%= s.title %></strong>
      <p class="mb-1"><em>Check-in:</em> <%= s.check_in_format %></p>
      <p class="mb-1"><em>Discussion:</em> <%= s.discussion_topic %></p>
      <p class="mb-1"><em>Activity:</em> <%= s.activity %></p>
      <p class="mb-0"><em>Closing:</em> <%= s.closing_ritual %></p>
    </div>
  <% end %>

  <h4>Boundary reminders</h4>
  <% @charter.boundary_reminders_list.each do |r| %>
    <p class="reminder-text"><%= r %></p>
  <% end %>

  <div class="charter-disclaimer mt-5 pt-3 border-top small text-muted">
    This charter is a starting draft, not a clinical or professional treatment plan.
    It is generated by AI based on a short description and the S.A.F.E. framework.
    Before running this group, review the charter with a qualified professional in your context
    and adapt it to your community's specific needs and regulatory environment.
    If your group is intended to address acute crisis or active clinical issues, do not use this tool.
    Refer members to a clinician.
  </div>
</div>
```

### 5.9 — Update `support_groups/show.html.erb`

The Phase 3 show page already has the `turbo_frame_tag "charter-region"` and the correct conditional rendering. Verify it renders the real partials (not the Phase 3 stubs). The charter card, session cards, and boundary panel partials are now available.

---

## RSpec — Phase 5

Run after completing all tasks above:

```bash
bundle exec rspec spec/requests/charters_spec.rb spec/requests/charters_print_spec.rb
```

### `spec/requests/charters_spec.rb`

```ruby
RSpec.describe "Charters", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:group) { create(:support_group, user: user) }
  let(:valid_response) { File.read(Rails.root.join("spec/fixtures/files/sample_grief_circle_response.json")) }

  before { sign_in_as(user) }

  describe "POST /support_groups/:id/charter (create)" do
    context "with stubbed successful Gemini response" do
      before { gemini_returns(valid_response) }

      it "calls GeminiService.generate with template 'minglegrid_charter_v1'"
      it "calls GeminiService.generate with all five expected variable keys"
      it "creates one GroupCharter record"
      it "creates exactly four LaunchSession records"
      it "creates an LlmRequest record with template_name 'minglegrid_charter_v1'"
      it "redirects to support_group_path with success flash"
    end

    context "with stubbed GeminiService::TimeoutError" do
      before { gemini_raises(GeminiService::TimeoutError) }

      it "renders a Turbo Stream response targeting 'charter-region'"
      it "does not create any GroupCharter records"
      it "does not create any LaunchSession records"
      it "response includes a retry message"
    end

    context "with stubbed GeminiService::BudgetExceededError" do
      before { gemini_raises(GeminiService::BudgetExceededError) }

      it "renders the budget-exceeded message"
      it "does not create records"
    end

    context "with stubbed GeminiService::GatekeeperError" do
      before { gemini_raises(GeminiService::GatekeeperError) }

      it "renders the gatekeeper message"
      it "does not create records"
    end

    it "returns 404 when a different user tries to trigger generation"

    context "unauthenticated" do
      before { sign_out }
      it "redirects to sign in"
    end
  end

  describe "POST /support_groups/:id/charter/regenerate" do
    let!(:existing_charter) { create(:group_charter, :with_sessions, support_group: group) }

    before { gemini_returns(valid_response) }

    it "destroys the existing charter before generating"
    it "destroys all existing LaunchSession records"
    it "creates a new GroupCharter"
    it "creates exactly four new LaunchSession records"
    it "redirects with 'Charter regenerated' notice"
  end
end
```

### `spec/requests/charters_print_spec.rb`

```ruby
RSpec.describe "Charters#print", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:group) { create(:support_group, :with_charter, user: user) }

  before { sign_in_as(user) }

  it "GET /support_groups/:id/charter/print returns 200 and renders the print layout"
  it "response body does not include the navbar"
  it "returns 404 when the group has no charter"
  it "returns 404 for a different user's group"

  context "unauthenticated" do
    before { sign_out }
    it "redirects to sign in"
  end
end
```

---

## Manual Checks — Phase 5

- [ ] `rails db:seed` — `AiTemplate` named `minglegrid_charter_v1` appears in `/admin/ai_templates`
- [ ] Open `minglegrid_charter_v1` in the admin test panel; enter sample inputs; confirm valid JSON is returned from Gemini (this is a real API call — have your `GEMINI_API_KEY` set)
- [ ] On a group show page with no charter: "Generate charter" button is visible with the disclaimer card above it
- [ ] Click "Generate charter" — button text changes to "Generating…" while request is in flight
- [ ] On success: charter card appears with purpose, structure, commitments, and agreements; four session cards visible in the horizontal scroll area; boundary reminders in sidebar
- [ ] Click a session card header — expands to show all four prose fields
- [ ] Click "Print charter" — opens print layout in a new tab with no navbar/footer; disclaimer at bottom
- [ ] Click "Regenerate" — confirm dialog appears; new charter replaces old one
- [ ] Temporarily set `AI_CALLS_PER_USER_PER_DAY=0` and click "Generate" — budget-exceeded error appears inline with retry option; restore the value afterward
- [ ] "Show raw response" toggle reveals raw JSON in the sidebar
- [ ] `bundle exec rspec spec/requests/charters_spec.rb spec/requests/charters_print_spec.rb` — all pass, zero real Gemini API calls (check for any googleapis.com in test logs)
