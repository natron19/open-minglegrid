# MingleGrid Demo - Spec Document

**Document Version:** 1.0
**Built On:** Open Demo Starter v2.0
**License:** MIT
**Target Footprint:** Single-user, localhost-only Rails 8 application

---

## 1. App Overview

MingleGrid Demo is an open source, single-feature Rails 8 application that turns a short description of a peer support group into a usable starter pack. The user describes the group they want to run, including its purpose, demographics, cadence, and host organization. Gemini returns a S.A.F.E. starter pack: a printable group charter, a four-session launch sequence, and two boundary reminders the facilitator can use when conversation drifts beyond what peer support can hold.

The problem it solves: designing a healthy peer support group from scratch requires years of facilitation experience that most volunteer leaders, HR staff, and community organizers do not have. Without structure, new groups drift, lose attendance, or step into territory that needs a clinician. The S.A.F.E. framework (Structure, Accountability, Formation, Evolution) embeds proven peer support practices, and this demo shows how AI plus a tight template can turn a short brief into a working charter and four-session runway in under a minute.

The indie hacker angle: this is one tool from a larger multi-tenant SaaS suite the author is building. The full version of MingleGrid is a multi-tenant platform with team collaboration, member management, recurring session scheduling, group health checks, agreement co-signing, and a coach role. This open source demo isolates the single most valuable thing the platform does (turn a group brief into a charter and launch plan) and ships it as a clean, small, locally-runnable Rails app.

This demo is open source under the MIT license, scoped to a single signed-in user, and runs locally. There is no organization model, no membership model, no shared groups, no recurring scheduler, and no member-facing experience. The user is the facilitator and the audience.

---

## 2. Customizations Applied to the Boilerplate

This is the full list of places this demo diverges from the default Open Demo Starter v2.0:

- `.env.example` updated with `APP_NAME=MingleGrid Demo`, `APP_TAGLINE=Describe your support group. Get a charter and a 4-session startup plan.`, and `APP_DESCRIPTION` set to a one-paragraph version of the App Overview.
- Accent color set in `app/assets/stylesheets/_accent.scss`: `--accent: #fdba74` (warm orange) and `--accent-hover: #fb923c`. A secondary accent variable `--accent-secondary: #93c5fd` (soft blue) is added for the boundary reminders panel and Session card chips.
- Navbar adds one link: "Groups" (points to `/support_groups`). The user dropdown and admin link remain unchanged.
- `home/index.html.erb` replaced with a MingleGrid landing pitch: a single hero with the tagline, a three-step explainer (Describe, Generate, Print), and a "Sign up to start" call to action. Copy points to the production site as a placeholder URL.
- `dashboard/show.html.erb` replaced with the user's group list. Empty state shows a single primary button: "Create your first group".
- UX pattern: group dashboard (card grid index) plus form-then-charter document (the show page is a printable charter card followed by a horizontal scroll of session cards and a sidebar with boundary reminders). This pulls from Pattern 4 (Bento Grid) on the show page and Pattern 1 (Prioritized List) on the index, simplified for one user.
- AI templates seeded into `db/seeds.rb`: `minglegrid_charter_v1`. Full content in Section 7.
- Three new domain models added: `SupportGroup`, `GroupCharter`, `LaunchSession`.
- One additional CSS file: `_minglegrid.scss` for the boundary reminder panel border treatment and the print stylesheet for the charter page. Total custom CSS stays under 80 lines.

---

## 3. Data Model

Three new domain models. Every record belongs to a user via `belongs_to :user` (directly or through the parent). All controllers scope queries to `current_user.support_groups`.

### SupportGroup

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key to User |
| `name` | string | Required, 2 to 80 characters |
| `purpose` | text | Required, 20 to 1000 characters. **(template variable)** |
| `target_demographics` | text | Optional, up to 500 characters. **(template variable)** |
| `meeting_cadence` | string | Required, one of `weekly`, `biweekly`, `monthly`. **(template variable)** |
| `session_length_minutes` | integer | Required, 30 to 180. **(template variable)** |
| `organization_type` | string | Required, one of `faith_community`, `nonprofit`, `workplace`, `online_cohort`, `other`. **(template variable)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :user`
- `has_one :group_charter, dependent: :destroy`

**Validations:**
- `name`, `purpose`, `meeting_cadence`, `session_length_minutes`, `organization_type` are required
- `purpose` length 20 to 1000
- `meeting_cadence` inclusion list
- `organization_type` inclusion list
- `session_length_minutes` inclusion in 30..180

### GroupCharter

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `support_group_id` | uuid | Foreign key, unique (one charter per group) |
| `purpose_statement` | text | Parsed from Gemini output |
| `meeting_structure` | text | Parsed from Gemini output |
| `member_commitments` | text | Parsed from Gemini output |
| `agreements` | text | 4 to 5 group agreements, parsed from output, stored as JSON array of strings |
| `boundary_reminders` | text | Two boundary reminder phrases, stored as JSON array of strings |
| `gemini_raw` | text | **(Gemini output, used for Show raw response toggle)** |
| `generated_at` | datetime | Set on successful generate |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :support_group`
- `has_one :user, through: :support_group`
- `has_many :launch_sessions, dependent: :destroy`

**Validations:**
- `support_group_id` uniqueness
- `gemini_raw` presence on save (the parser must have something to read; an empty string is a generation failure)

### LaunchSession

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `group_charter_id` | uuid | Foreign key |
| `session_number` | integer | 1, 2, 3, or 4 |
| `title` | string | E.g., "Trust building", "Expectation setting" |
| `check_in_format` | text | Opening routine for the session |
| `discussion_topic` | text | Topic with one or two prompts |
| `activity` | text | One structured activity description |
| `closing_ritual` | text | Closing routine |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :group_charter`
- `has_one :support_group, through: :group_charter`

**Validations:**
- `session_number` inclusion in 1..4
- `session_number` uniqueness scoped to `group_charter_id`
- `title`, `check_in_format`, `discussion_topic`, `activity`, `closing_ritual` presence

The `User`, `AiTemplate`, and `LlmRequest` models come from the boilerplate and are not redescribed here.

---

## 4. Routes

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/support_groups` | `support_groups#index` | List the current user's groups (card grid) |
| GET | `/support_groups/new` | `support_groups#new` | Render the create-group form |
| POST | `/support_groups` | `support_groups#create` | Persist the group, redirect to show |
| GET | `/support_groups/:id` | `support_groups#show` | Render group dashboard with charter and sessions if present |
| GET | `/support_groups/:id/edit` | `support_groups#edit` | Edit group inputs (does not regenerate the charter) |
| PATCH | `/support_groups/:id` | `support_groups#update` | Update group inputs |
| DELETE | `/support_groups/:id` | `support_groups#destroy` | Delete the group and its charter and sessions |
| POST | `/support_groups/:id/charter` | `charters#create` | Trigger Gemini call, build charter and four sessions |
| POST | `/support_groups/:id/charter/regenerate` | `charters#regenerate` | Replace charter and sessions with a fresh generation |
| GET | `/support_groups/:id/charter/print` | `charters#print` | Render printable, single-page charter view (no chrome) |

All HTML responses, RESTful conventions. Auth and admin routes inherited from the boilerplate.

---

## 5. Controllers and Actions

### `SupportGroupsController`

- `index` Loads `current_user.support_groups.order(updated_at: :desc)`. Renders the card grid.
- `new` Builds an unsaved `SupportGroup` for form rendering.
- `create` Permits `name`, `purpose`, `target_demographics`, `meeting_cadence`, `session_length_minutes`, `organization_type`. Saves under `current_user.support_groups.build`. On success, redirects to the group show page with a flash hinting that the user can now generate the charter. On validation failure, re-renders `new`.
- `show` Loads the group, charter (if present), and ordered sessions. Renders the dashboard.
- `edit`, `update`, `destroy` Standard RESTful behavior. Edits are not auto-applied to an existing charter; the user must regenerate to update the AI output.

### `ChartersController`

This is where the Gemini integration lives.

- `create` The action that triggers `GeminiService.generate(template: "minglegrid_charter_v1", variables: {...})`. Loads the parent `SupportGroup` from `current_user`, builds the variables hash from group fields, calls Gemini, parses the JSON response, persists the `GroupCharter` and four `LaunchSession` records inside a single transaction, then redirects to the group show page with a success flash. On any `GeminiService::GeminiError` subclass, renders an inline alert partial (provided by the boilerplate) with a retry button targeting this same action.
- `regenerate` Same as `create` but first destroys the existing charter and sessions inside the transaction. Used when the user wants a fresh attempt without changing the inputs.
- `print` Renders the charter using the `print` layout (no navbar, no footer, white background, optimized for printing or saving as PDF from the browser).

### Controller Conventions Inherited from the Boilerplate

- All controllers inherit from `ApplicationController`, which already requires authentication.
- All queries scope through `current_user`. There is no admin override on domain data.
- Strong parameters for every form.
- `rescue GeminiService::GeminiError => e` wraps the Gemini call in `ChartersController#create` and `#regenerate`; the boilerplate's error partial is rendered inline, status code 200 (so Turbo can swap the frame). Specific subclass messaging:
  - `GatekeeperError` shows "Your group description triggered a safety check. Try shortening it or removing copied content."
  - `BudgetExceededError` shows "Daily AI limit reached. Try again tomorrow."
  - `TimeoutError` shows "Gemini took too long. Click retry."
  - `GeminiError` (other) shows a generic friendly message with a retry button.

---

## 6. Views

### Layout Overrides

- `application.html.erb` is unchanged from the boilerplate; only the navbar yields the "Groups" link via the navbar partial override.
- `layouts/print.html.erb` is new. Minimal HTML with the charter content, no chrome, browser print stylesheet. Used only by `charters#print`.

### `home/index.html.erb`

Hero + three-column "How it works" + sign-up CTA. Replaces the boilerplate's placeholder home.

### `dashboard/show.html.erb`

Replaced with a redirect or a simple "Go to your groups" panel. The dashboard is a thin wrapper that surfaces the group index for signed-in users; the navbar's "Groups" link is the canonical entry point.

### `support_groups/index.html.erb`

Bootstrap card grid (3 across on desktop, 1 across on mobile). Each card shows: group name, organization type chip, cadence chip, status badge ("Charter ready" or "No charter yet"), and a link to the show page. Empty state has a centered illustration placeholder, the tagline, and a single primary "Create your first group" button.

### `support_groups/new.html.erb` and `support_groups/edit.html.erb`

Single-column form. Fields:

- `name` (text input)
- `purpose` (textarea, 4 rows, with a 1000-character counter)
- `target_demographics` (textarea, 2 rows, optional)
- `meeting_cadence` (radio group: Weekly, Biweekly, Monthly)
- `session_length_minutes` (number input with helper text suggesting 60 or 90)
- `organization_type` (select: Faith community, Nonprofit, Workplace, Online cohort, Other)

A primary "Save group" button; on the new form, the helper text under the button reminds the user that creating the group does not yet call AI; the next step on the show page does.

### `support_groups/show.html.erb`

The form-then-charter dashboard. Three regions:

1. **Header strip.** Group name, organization type chip, cadence chip, edit and delete links.
2. **Main column.**
   - If no charter exists, a single large "Generate charter" call to action with helper copy describing what Gemini will produce. The button posts to `/support_groups/:id/charter`.
   - If a charter exists, the printable charter card at the top (purpose statement, meeting structure, member commitments, agreements list), followed by a horizontal scroll of four session cards labeled "Session 1" through "Session 4". Each session card expands (Bootstrap collapse) to show check-in format, discussion topic, activity, and closing ritual. Below the sessions, a "Print charter" button (links to `/charter/print`) and a "Regenerate" button (POST to `/charter/regenerate`, with a confirm dialog).
3. **Sidebar (right column on desktop, collapsed accordion on mobile).** A muted "Boundary reminders" panel using the secondary accent (`#93c5fd`). Always visible on desktop; this is intentional, since the reminders are most useful when planning a session. Below the reminders panel, a "Show raw response" toggle (Bootstrap collapse) reveals `group_charter.gemini_raw`.

The Generate Charter button uses a Turbo Frame so the page does not full-reload during the Gemini call. A spinner partial (provided by the boilerplate) sits in the frame while the request is in flight; on success, the frame is replaced with the charter card and sessions; on error, the inline error alert is rendered with a retry button.

### `support_groups/_form.html.erb`, `support_groups/_card.html.erb`, `charters/_charter_card.html.erb`, `charters/_session_card.html.erb`, `charters/_boundary_panel.html.erb`

Standard partials for the views above. The session card uses an accordion-style expand or collapse and shows a small "Session N" badge in the accent color.

### `charters/print.html.erb`

The full charter rendered for printing on a single page (purpose, structure, commitments, all agreements, all four sessions in compact format, both boundary reminders). Uses the `print` layout. CSS targets `@media print` for page break behavior.

Every view that displays Gemini output includes the "Show raw response" toggle revealing the `gemini_raw` field. This is the inherited UX expectation from the boilerplate and is implemented here on the show page sidebar.

---

## 7. AI Templates and Gemini Integration

This demo seeds exactly one template. The structural safety constraint (boundary reminders must always be present) is enforced inside the system prompt, not in Ruby. The parser refuses to persist a charter without two boundary reminders; if the model ever drops them, the user sees a retry alert.

### Template: `minglegrid_charter_v1`

- **Name:** `minglegrid_charter_v1`
- **Description:** Generates a S.A.F.E. peer support group charter, a four-session launch sequence, and two facilitator boundary reminders.
- **Model:** `gemini-2.0-flash` (default, justified by cost; the JSON output is structured enough that a more capable model is not required for v1).
- **Max output tokens:** 3000 (raised from the 2000 default because the response includes a charter plus four full session blocks plus boundary reminders; testing showed 2000 occasionally truncates Session 4).
- **Temperature:** 0.6 (slightly below the 0.7 default; lower temperature produces more consistent JSON structure and more conservative recommendations, which matches the safety posture of peer support).

#### `system_prompt`

```
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
```

#### `user_prompt_template`

```
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
```

#### Variables Consumed

- `{{purpose}}` from `SupportGroup.purpose`
- `{{target_demographics}}` from `SupportGroup.target_demographics` (defaults to "not specified" if blank)
- `{{meeting_cadence}}` from `SupportGroup.meeting_cadence`
- `{{session_length_minutes}}` from `SupportGroup.session_length_minutes`
- `{{organization_type}}` from `SupportGroup.organization_type` (humanized: `faith_community` becomes "faith community")

#### `notes` (author's notes for the admin UI)

```
What this prompt is doing:
- Using JSON-strict output to make parsing predictable in Ruby
- Embedding the safety refusal path in the system prompt so the model will not
  produce a charter for a clinical context regardless of how the brief is phrased
- Forcing the four-session arc to S.A.F.E. Formation phases so the output
  reads as a coherent launch, not four disconnected sessions
- Forcing two boundary reminders that are specific to the group's purpose,
  not generic. This is the most-iterated part of the prompt; in early versions
  the model produced bland generic reminders ("remember this is not therapy").
  The "specific risks adjacent to this group's purpose" phrasing pushed it
  toward useful phrases like "I want to pause here. What you are describing
  sounds like it deserves a one-on-one with a counselor."

Watch for:
- Drift toward clinical language in the agreements (the system prompt blocks this)
- Session 3 (deepening) producing topics that go too far for a peer group;
  if this happens, lower the temperature further
- Too-similar boundary reminders. If both reminders are paraphrases of the
  same idea, regenerate

Known failure modes:
- On rare occasions the model emits a code fence around the JSON. The parser
  strips fences before parsing
- Token truncation: very long purpose strings can push the response past the
  3000 token cap. The form caps purpose at 1000 chars to mitigate
- The clinical refusal triggers correctly for "active suicidal ideation"
  but is less reliable for "court-ordered DUI program". v2 may need a
  small list of refusal triggers in the user prompt
```

#### Where It Is Called

`ChartersController#create` and `ChartersController#regenerate` both call:

```ruby
GeminiService.generate(
  template: "minglegrid_charter_v1",
  variables: {
    purpose: @support_group.purpose,
    target_demographics: @support_group.target_demographics.presence || "not specified",
    meeting_cadence: @support_group.meeting_cadence,
    session_length_minutes: @support_group.session_length_minutes,
    organization_type: @support_group.organization_type.humanize.downcase
  }
)
```

#### Expected Output Format

Single JSON object, schema as defined in the system prompt. The parser is a small `CharterParser` class that:

1. Strips any leading or trailing code fences.
2. Calls `JSON.parse` with a rescue.
3. If the parsed hash includes the key `refusal`, the controller raises `GeminiService::GeminiError` with the refusal message; the user sees the safety block as an inline alert.
4. Validates the schema (4 to 5 agreements, exactly 4 sessions with numbers 1 through 4, exactly 2 boundary reminders). On schema failure, raises a parsing error and the user sees a retry alert.
5. Builds the `GroupCharter` and four `LaunchSession` records inside a transaction.
6. Stores the original raw JSON string in `group_charter.gemini_raw`.

#### How the Response is Rendered

- `purpose_statement`, `meeting_structure`, and `member_commitments` render as paragraphs inside the charter card.
- `agreements` renders as a numbered list inside the charter card.
- `sessions` renders as four expandable session cards in a horizontal scroll.
- `boundary_reminders` renders in the sidebar boundary panel, each on its own line with a quote-mark glyph.
- `gemini_raw` renders inside the "Show raw response" Bootstrap collapse on the show page.

The boilerplate's gatekeeper, budget checker, request log, timeout, and fail-soft error UI apply to this Gemini call automatically and are not redescribed here.

---

## 8. AI Safety Considerations (Specific to This App)

This is one of the higher-stakes demos in the portfolio. Peer support is adjacent to mental health, recovery, grief, and trauma. The author treats this section as the most important part of the spec, not the least.

### Content Sensitivity

The app's domain (peer support groups for grief, recovery, parenting, career transitions, workplace wellness) sits next to clinical mental health without being clinical mental health. This is exactly the seam where AI output can do real harm if a user mistakes a charter for a treatment plan. The clinical refusal path in the system prompt is the first line of defense; the visible "AI-generated content can be incorrect. Verify before acting." footer is the second; the app-specific disclaimer described below is the third.

### Consequential Outputs

The realistic worst case is a volunteer facilitator running a group on the strength of an AI-generated charter without consulting any human reviewer, and a member surfaces a clinical issue (active suicidal ideation, severe substance use, intimate partner violence) the facilitator is not equipped to handle. The boundary reminders mitigate this by giving the facilitator literal phrases to redirect to a professional, but the demo cannot guarantee facilitator skill or judgment. The disclaimer below names this directly.

### Domain Accuracy Requirements

There is no single ground truth for "what a peer support group charter should say". The S.A.F.E. framework is the author's, not a clinical standard. Users in regulated domains (recovery groups for court-mandated programs, workplace wellness programs that need EAP integration, faith communities with denominational standards) need to bring their own domain expertise to review the charter. The disclaimer says this.

### App-Specific Disclaimers

Beyond the boilerplate's footer note, the show page renders an inline disclaimer card directly above the "Generate charter" button on first generation, and at the top of the charter card after generation:

> This charter is a starting draft, not a clinical or professional treatment plan. It is generated by AI based on a short description and the S.A.F.E. framework. Before running this group, review the charter with a qualified professional in your context (a licensed counselor, a denominational leader, an HR partner, or a recovery program coordinator) and adapt it to your community's specific needs and regulatory environment. If your group is intended to address acute crisis or active clinical issues, do not use this tool. Refer members to a clinician.

The print layout includes the same disclaimer at the bottom of the printed charter so it travels with the document.

### Tightened Settings

This demo justifies a tightened operational posture compared to the boilerplate defaults:

- `AI_CALLS_PER_USER_PER_DAY=20` in `.env.example` (down from the 50 default). Generating charters is a deliberate act, not a high-frequency one, and a lower cap reduces the chance of someone running 50 generations to find one they like and choosing a low-quality outlier.
- `max_output_tokens` set to 3000 on the template, with a hard parser-level rejection of responses over 3500 tokens (interpreted as a runaway response).
- `temperature` set to 0.6, slightly below the 0.7 default, for more consistent and conservative output.

### What This Demo Deliberately Does Not Do (For Safety Reasons)

| Omitted | Rationale |
|---|---|
| No member-facing experience | The charter is a facilitator tool, not a member tool. There is no path for members to log in, share feelings, or interact with AI. |
| No discussion topic generation per session | Out of scope for this demo; the production app handles ongoing topic generation with much tighter controls. The demo intentionally stops at the four-session launch sequence. |
| No clinical or therapeutic language | The system prompt refuses clinical contexts and the agreements section specifically excludes diagnostic or treatment language. |
| No personalization to named members | Inputs describe the group, not individuals. The schema does not accept member names or stories. |
| No saved health checks, progress tracking, or session notes | Storing this kind of content tied to identity is the explicit thing the production app does not do, and the demo follows the same posture. |
| No automatic regeneration or streaming | The user clicks regenerate intentionally; there is no background refresh that could surface a different charter mid-planning. |

The omissions list mirrors the boilerplate's pattern (each concern was considered, a deliberate choice was made). For a portfolio reviewer, the existence of this section is itself a signal: the author thought about peer support risk surface and shipped a tool that respects it.

---

## 9. RSpec Outline

New spec files added on top of the boilerplate's existing test suite.

### `spec/models/support_group_spec.rb`

- Validates required fields, length bounds on `purpose`, and inclusion lists for `meeting_cadence` and `organization_type`.
- Validates `session_length_minutes` is between 30 and 180.
- Confirms `belongs_to :user` and `has_one :group_charter` associations.
- Confirms destroying a `SupportGroup` cascades to its `GroupCharter` and `LaunchSession` records.

### `spec/models/group_charter_spec.rb`

- Validates uniqueness of `support_group_id`.
- Validates presence of `gemini_raw`.
- Confirms `has_many :launch_sessions, dependent: :destroy`.
- Confirms `agreements` and `boundary_reminders` round-trip through JSON serialization.

### `spec/models/launch_session_spec.rb`

- Validates `session_number` inclusion in 1..4.
- Validates `session_number` uniqueness per `group_charter`.
- Validates required prose fields are present.

### `spec/services/charter_parser_spec.rb`

- Parses a well-formed JSON response into the expected hash.
- Strips a Markdown code fence wrapper if the model emits one.
- Raises a parsing error if the schema is missing keys.
- Raises a parsing error if `sessions` does not contain exactly 4 entries with numbers 1 through 4.
- Raises a parsing error if `boundary_reminders` does not contain exactly 2 entries.
- Treats a `refusal` key in the parsed hash as a refusal signal and raises with the refusal message.

### `spec/requests/support_groups_spec.rb`

- A signed-in user can list, create, view, edit, update, and delete their own groups.
- A different signed-in user cannot view or edit another user's group (returns 404).
- Validation errors on create re-render the new form with the error messages.

### `spec/requests/charters_spec.rb`

This is the AI-touching spec. It uses the boilerplate's `GeminiService` test double.

- `POST /support_groups/:id/charter` calls `GeminiService.generate` with template `"minglegrid_charter_v1"` and the expected variables hash. Verified using the test double.
- On a stubbed successful response, a `GroupCharter` and four `LaunchSession` records are created inside a transaction; the user is redirected to the show page with a success flash.
- On a stubbed `GeminiService::TimeoutError`, the action renders the inline error partial with a retry button and does not create any records.
- On a stubbed `GeminiService::BudgetExceededError`, the action renders the budget-exceeded message.
- On a stubbed `GatekeeperError`, the action renders the gatekeeper message.
- A different signed-in user cannot trigger generation on another user's group (404).
- Verification that an `LlmRequest` record is created on each AI call (the boilerplate creates this record; the spec confirms it exists with the expected `template_name`).
- `POST /support_groups/:id/charter/regenerate` destroys the existing charter and sessions before generating a new one.

### `spec/requests/charters_print_spec.rb`

- Renders the print layout (no navbar, no footer).
- Returns 404 when the group has no charter yet.
- A different signed-in user cannot view another user's print page.

The boilerplate's specs (`user_spec.rb`, `ai_template_spec.rb`, `llm_request_spec.rb`, `gemini_service_spec.rb`, `ai_gatekeeper_spec.rb`, `ai_budget_checker_spec.rb`, the auth and admin request specs) are inherited and not redescribed.

---

## 10. Seed Data

`db/seeds.rb` extends the boilerplate's seeded admin demo user with two parts.

### AiTemplate Seed

One `AiTemplate` record with the full content from Section 7:

- `name: "minglegrid_charter_v1"`
- `description: "Generates a S.A.F.E. peer support group charter, four-session launch sequence, and two facilitator boundary reminders."`
- `system_prompt:` full text from Section 7
- `user_prompt_template:` full text from Section 7
- `model: "gemini-2.0-flash"`
- `max_output_tokens: 3000`
- `temperature: 0.6`
- `notes:` full author's notes from Section 7

The seed uses `find_or_create_by!(name: ...)` so re-running seeds is idempotent.

### Domain Seeds

Three sample `SupportGroup` records owned by the seeded admin user (`demo@example.com`), each chosen to demonstrate variety and the safety posture:

1. **"Tuesday Grief Circle"** - Faith community, weekly, 90 minutes. Purpose: peer support for adults in the first year of grieving a spouse or parent. Demographics: adults over 40 in a small congregation.
2. **"New Manager Cohort"** - Workplace, biweekly, 60 minutes. Purpose: peer support and skill-sharing for first-time engineering managers in their first six months in role. Demographics: engineering managers in a mid-sized tech company.
3. **"Sober Curious Online"** - Online cohort, weekly, 60 minutes. Purpose: peer support for people exploring a 90-day break from alcohol without committing to recovery program identity. Demographics: adults across multiple time zones.

For one of these (the Tuesday Grief Circle), the seed also creates a fully populated `GroupCharter` and four `LaunchSession` records using a hand-written sample output. This means the user signing in as `demo@example.com` for the first time sees one fully populated group on the index, so the empty state is visible only on a fresh, untouched second user account. The other two groups have no charter, demonstrating the "Generate charter" call to action.

The hand-written sample output in the seed lives in a fixture file (`spec/fixtures/files/sample_grief_circle_response.json`) so the same payload can be reused in specs.

---

## 11. README Additions

The boilerplate ships a README template; this demo adds or replaces these sections only.

### App Name, Tagline, and Description

```
# MingleGrid Demo

> Describe your support group. Get a charter and a 4-session startup plan.

MingleGrid Demo turns a short description of a peer support group into a
printable charter, a four-session launch sequence, and two facilitator
boundary reminders. It is a single-feature, locally-runnable Rails 8 app
built on the Open Demo Starter v2.0.
```

### Screenshot Placeholder

A note: "Screenshots: see `docs/screenshots/`. Replace with your own when forking."

### Why I Built This

```
## Why I Built This

I am building a multi-tenant SaaS suite for community work, and MingleGrid is
the peer support tool in that suite. The full version handles organizations,
member rolls, recurring scheduling, and group health checks. This open source
demo isolates the most useful 60 seconds of that experience: turning a brief
into a charter you can take to the first meeting.

The full product lives at https://minglegrid.app (placeholder). This repo is
MIT licensed; clone it, run it, change the prompt, and see how a small Rails
8 app plus Gemini plus a tight template handles a sensitive domain.
```

### Editing the AI Prompt

```
## Editing the AI Prompt

The prompt is data, not code. Sign in as `demo@example.com` / `password123`
(seeded admin), open `/admin/ai_templates`, and click into
`minglegrid_charter_v1` to edit the system prompt, user prompt template,
model, max tokens, and temperature. The right-side test panel runs the live
draft against Gemini without saving so you can iterate. Save when satisfied.
```

### App-Specific Setup

No additional setup beyond `bin/setup`. `GEMINI_API_KEY` is the only required environment variable; instructions are inherited from the boilerplate.

The standard "Stack", "Setup", "License", "AI Safety Posture", and "About the Author" sections come from the boilerplate template and are not rewritten.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

### UX Pattern Choice

This demo combines two patterns:

- **Group index page:** Card grid (Pattern 1 simplified). Three columns on desktop, one column on mobile. Each card uses Bootstrap's `card` component with the accent color on the card title hover state and on the "Generate charter" button.
- **Group show page:** Form-then-charter document (a custom blend of Pattern 4 Bento Grid and Pattern 10 Document Workspace). The charter is a printable document; the sessions are a horizontal scroll of expandable cards; the boundary reminders sit in a sticky sidebar. This visual composition is the demo's signature; no other demo in the portfolio uses it.

### Accent Color Application

Warm orange (`#fdba74`) is used consistently:

- Primary buttons (Generate charter, Save group, Regenerate) use `bg-accent` (a Bootstrap utility extension that maps to `var(--accent)`).
- Active navbar link state uses `var(--accent)` as the underline color.
- Card hover state on the index uses a subtle `var(--accent)` 1px border.
- Session card "Session N" badges use `var(--accent)` as the background.
- All anchor links default to `var(--accent)`; hover state uses `var(--accent-hover)`.

Soft blue (`#93c5fd`, `--accent-secondary`) is used only for:

- The boundary reminders sidebar panel border and quote glyph.
- The session card chip showing the session number on the horizontal scroll.

This restraint (one accent for action, one accent for the sensitive content) keeps the visual language honest: orange means "do this", blue means "be careful here".

### Custom CSS

`app/assets/stylesheets/_minglegrid.scss` adds:

- Boundary reminder panel border treatment (1px dashed `var(--accent-secondary)`, 8px padding, slightly muted background).
- Session card horizontal scroll snap behavior (CSS scroll snap; one card per snap).
- Print stylesheet for the charter print page (page break rules, hidden navbar, white background, 12pt body type).

Total custom CSS stays under 80 lines. Everything else uses Bootstrap utility classes.

---

*v1.0 - MingleGrid Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
