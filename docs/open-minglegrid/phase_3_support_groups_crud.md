# Phase 3 — Support Groups CRUD

**App:** MingleGrid Demo (built on Open Demo Starter v2.0)  
**Goal:** Build the full create-read-update-delete flow for `SupportGroup`. No AI yet — the show page displays the "Generate charter" placeholder but the button is not wired until Phase 5.  
**Spec reference:** [`minglegrid-demo-spec.md`](minglegrid-demo-spec.md) — Sections 4, 5, 6  
**Depends on:** Phase 2 complete — all three models, migrations, and factories exist  
**Next phase:** [phase_4_charter_parser.md](phase_4_charter_parser.md)

**Before starting, read:**
- `CLAUDE.md` — Stimulus-only JS, `turbo_stream.update` never `replace`, no plain `<script>` tags
- `docs/turbo-stimulus-patterns.md` — Turbo Stream and Bootstrap interaction patterns
- `docs/testing.md` — request spec patterns and the `sign_in_as` helper

---

## Tasks

### 3.1 — Routes

Add to `config/routes.rb`:

```ruby
resources :support_groups do
  member do
    resource :charter, only: [:create], controller: "charters" do
      post :regenerate, on: :member
      get  :print,      on: :member
    end
  end
end
```

Verify these named helpers are available after adding:
- `support_groups_path` — index
- `support_group_path(id)` — show
- `new_support_group_path` — new form
- `edit_support_group_path(id)` — edit form
- `support_group_charter_path(id)` — charter create (POST)
- `regenerate_support_group_charter_path(id)` — regenerate (POST)
- `print_support_group_charter_path(id)` — print (GET)

Run `rails routes | grep support_group` to confirm all helpers are correct before proceeding.

### 3.2 — `app/controllers/support_groups_controller.rb`

```ruby
class SupportGroupsController < ApplicationController
  before_action :set_support_group, only: [:show, :edit, :update, :destroy]

  def index
    @support_groups = current_user.support_groups.order(updated_at: :desc)
  end

  def new
    @support_group = current_user.support_groups.build
  end

  def create
    @support_group = current_user.support_groups.build(support_group_params)
    if @support_group.save
      redirect_to @support_group, notice: "Group created. Generate your charter below."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @charter  = @support_group.group_charter
    @sessions = @charter&.launch_sessions&.order(:session_number)
  end

  def edit; end

  def update
    if @support_group.update(support_group_params)
      redirect_to @support_group, notice: "Group updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @support_group.destroy
    redirect_to support_groups_path, notice: "Group deleted."
  end

  private

  def set_support_group
    @support_group = current_user.support_groups.find(params[:id])
  end

  def support_group_params
    params.require(:support_group).permit(
      :name, :purpose, :target_demographics,
      :meeting_cadence, :session_length_minutes, :organization_type
    )
  end
end
```

`current_user.support_groups.find(params[:id])` raises `ActiveRecord::RecordNotFound` (→ 404) when the group belongs to a different user. Never use a bare `SupportGroup.find` — always scope to `current_user`.

### 3.3 — `app/views/support_groups/index.html.erb`

Bootstrap card grid: 3 columns on `col-md-4`, 1 column on mobile. Render `support_groups/_card.html.erb` for each group. Empty state when no groups exist.

```erb
<div class="container py-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>Your groups</h1>
    <%= link_to "New group", new_support_group_path, class: "btn bg-accent" %>
  </div>

  <% if @support_groups.empty? %>
    <div class="text-center text-muted py-5">
      <p class="fs-5">You have no groups yet.</p>
      <%= link_to "Create your first group", new_support_group_path, class: "btn bg-accent" %>
    </div>
  <% else %>
    <div class="row g-3">
      <% @support_groups.each do |group| %>
        <div class="col-md-4">
          <%= render "support_groups/card", group: group %>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
```

### 3.4 — `app/views/support_groups/_card.html.erb`

```erb
<div class="card card-hover h-100">
  <div class="card-body">
    <h5 class="card-title"><%= group.name %></h5>
    <span class="badge bg-secondary me-1"><%= group.organization_type.humanize %></span>
    <span class="badge bg-secondary"><%= group.meeting_cadence.humanize %></span>
  </div>
  <div class="card-footer d-flex justify-content-between align-items-center">
    <% if group.group_charter.present? %>
      <span class="badge bg-success">Charter ready</span>
    <% else %>
      <span class="badge bg-secondary text-muted">No charter yet</span>
    <% end %>
    <%= link_to "View", support_group_path(group), class: "btn btn-sm bg-accent" %>
  </div>
</div>
```

### 3.5 — `app/views/support_groups/new.html.erb` and `edit.html.erb`

```erb
<%# new.html.erb %>
<div class="container py-4">
  <h1>Create a new group</h1>
  <%= render "form", support_group: @support_group %>
</div>
```

```erb
<%# edit.html.erb %>
<div class="container py-4">
  <h1>Edit group — <%= @support_group.name %></h1>
  <%= render "form", support_group: @support_group %>
</div>
```

### 3.6 — `app/views/support_groups/_form.html.erb`

All fields must use `ENV.fetch` indirection for labels only where relevant; field names come from the model constants.

```erb
<%= form_with model: support_group, class: "col-lg-8" do |f| %>
  <%= render "shared/error_messages", object: support_group %>

  <div class="mb-3">
    <%= f.label :name, class: "form-label" %>
    <%= f.text_field :name, class: "form-control" %>
  </div>

  <div class="mb-3">
    <%= f.label :purpose, class: "form-label" %>
    <%= f.text_area :purpose, rows: 4, class: "form-control",
        data: { controller: "char-counter", char_counter_max_value: 1000 } %>
    <div class="form-text">Up to 1000 characters. Be specific — the AI uses this to calibrate tone and activities.</div>
  </div>

  <div class="mb-3">
    <%= f.label :target_demographics, "Target demographics (optional)", class: "form-label" %>
    <%= f.text_area :target_demographics, rows: 2, class: "form-control" %>
    <div class="form-text">Optional — describe age range, life stage, or shared context.</div>
  </div>

  <div class="mb-3">
    <%= f.label :meeting_cadence, class: "form-label" %>
    <% SupportGroup::MEETING_CADENCES.each do |cadence| %>
      <div class="form-check">
        <%= f.radio_button :meeting_cadence, cadence, class: "form-check-input" %>
        <%= f.label "meeting_cadence_#{cadence}", cadence.humanize, class: "form-check-label" %>
      </div>
    <% end %>
  </div>

  <div class="mb-3">
    <%= f.label :session_length_minutes, "Session length (minutes)", class: "form-label" %>
    <%= f.number_field :session_length_minutes, class: "form-control", placeholder: "e.g. 60 or 90", min: 30, max: 180 %>
  </div>

  <div class="mb-3">
    <%= f.label :organization_type, class: "form-label" %>
    <%= f.select :organization_type,
        SupportGroup::ORGANIZATION_TYPES.map { |t| [t.humanize, t] },
        { include_blank: "— select one —" },
        class: "form-select" %>
  </div>

  <div class="mt-4">
    <%= f.submit support_group.new_record? ? "Create group" : "Save changes",
        class: "btn bg-accent" %>
    <% if support_group.new_record? %>
      <p class="text-muted small mt-2">Creating the group doesn't call AI yet. You'll generate the charter from the group page.</p>
    <% end %>
  </div>
<% end %>
```

If a `char-counter` Stimulus controller doesn't already exist in the boilerplate, either skip the `data-controller` attribute (use the static helper text) or create a minimal Stimulus controller. Never use inline `oninput` JavaScript.

### 3.7 — `app/views/support_groups/show.html.erb`

Three regions. The charter region is a placeholder here — fully wired in Phase 5.

```erb
<div class="container py-4">
  <%# Region 1 — Header strip %>
  <div class="d-flex justify-content-between align-items-start mb-4">
    <div>
      <h1><%= @support_group.name %></h1>
      <span class="badge bg-secondary me-1"><%= @support_group.organization_type.humanize %></span>
      <span class="badge bg-secondary"><%= @support_group.meeting_cadence.humanize %></span>
    </div>
    <div class="d-flex gap-2">
      <%= link_to "Edit", edit_support_group_path(@support_group), class: "btn btn-sm btn-outline-secondary" %>
      <%= button_to "Delete", @support_group, method: :delete, class: "btn btn-sm btn-outline-danger",
          data: { turbo_confirm: "Delete this group and its charter?" } %>
    </div>
  </div>

  <div class="row g-4">
    <%# Region 2 — Main column %>
    <div class="col-lg-8">
      <%# Disclaimer — always visible %>
      <div class="alert alert-warning small mb-4">
        This charter is a starting draft, not a clinical or professional treatment plan.
        It is generated by AI based on a short description and the S.A.F.E. framework.
        Before running this group, review the charter with a qualified professional in your context
        (a licensed counselor, a denominational leader, an HR partner, or a recovery program coordinator)
        and adapt it to your community's specific needs and regulatory environment.
        If your group is intended to address acute crisis or active clinical issues, do not use this tool.
        Refer members to a clinician.
      </div>

      <%# Charter region — placeholder until Phase 5 %>
      <%= turbo_frame_tag "charter-region" do %>
        <% if @charter.nil? %>
          <%= render "charters/generate_cta", support_group: @support_group %>
        <% else %>
          <%= render "charters/charter_card", support_group: @support_group, charter: @charter %>
          <div class="session-scroll mt-3">
            <% @sessions.each do |session| %>
              <%= render "charters/session_card", session: session %>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>

    <%# Region 3 — Sidebar %>
    <div class="col-lg-4">
      <div id="boundary-panel">
        <% if @charter %>
          <%= render "charters/boundary_panel", charter: @charter %>
        <% else %>
          <p class="text-muted small">Boundary reminders will appear here after you generate a charter.</p>
        <% end %>
      </div>

      <% if @charter %>
        <div class="mt-3">
          <a class="btn btn-sm btn-outline-secondary" data-bs-toggle="collapse" href="#raw-response">
            Show raw response
          </a>
          <div class="collapse mt-2" id="raw-response">
            <pre class="small text-muted" style="max-height: 300px; overflow-y: auto;"><%= @charter.gemini_raw %></pre>
          </div>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

The `charters/generate_cta`, `charters/charter_card`, `charters/session_card`, and `charters/boundary_panel` partials are built in Phase 5. For now, create stub partials that render placeholder text so the show page doesn't error:

```erb
<%# app/views/charters/_generate_cta.html.erb (Phase 3 stub) %>
<p class="text-muted">Charter generation coming in Phase 5.</p>
```

---

## RSpec — Phase 3

Run after completing all tasks above:

```bash
bundle exec rspec spec/requests/support_groups_spec.rb
```

### `spec/requests/support_groups_spec.rb`

```ruby
RSpec.describe "SupportGroups", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let!(:group) { create(:support_group, user: user) }

  # Access control
  it "unauthenticated GET /support_groups redirects to sign in"
  it "unauthenticated GET /support_groups/:id redirects to sign in"

  # Index
  it "GET /support_groups returns 200 for signed-in user"
  it "GET /support_groups only shows current user's groups"

  # Create
  it "POST /support_groups with valid params creates a group and redirects to show"
  it "POST /support_groups with invalid params re-renders new (status 422)"
  it "POST /support_groups sets user to current_user"

  # Show
  it "GET /support_groups/:id returns 200 for owner"
  it "GET /support_groups/:id returns 404 for different user"

  # Update
  it "PATCH /support_groups/:id updates and redirects to show for owner"
  it "PATCH /support_groups/:id with invalid params re-renders edit (status 422)"
  it "PATCH /support_groups/:id returns 404 for different user"

  # Destroy
  it "DELETE /support_groups/:id destroys and redirects to index for owner"
  it "DELETE /support_groups/:id returns 404 for different user"

  # Error messages
  it "create with invalid params shows error messages in response body"
end
```

Every example that tests a protected route must call `sign_in_as(user)` first (from `spec/support/authentication_helpers.rb`).

---

## Manual Checks — Phase 3

- [ ] Visit `/support_groups` while signed in — shows empty state with "Create your first group" button
- [ ] Create a group — form validates all required fields; trying to submit blank shows errors
- [ ] After successful create, redirected to show page with success flash
- [ ] Show page renders the disclaimer card and the Phase 3 charter stub ("Charter generation coming in Phase 5.")
- [ ] Edit a group — form pre-fills all fields correctly
- [ ] Delete a group — confirm dialog appears; after confirm, group disappears from index
- [ ] Attempting to visit another user's group show page returns 404 (check in an incognito window signed in as a different account)
- [ ] "Groups" navbar link is now functional and navigates to the index
- [ ] `bundle exec rspec spec/requests/support_groups_spec.rb` — all pass
