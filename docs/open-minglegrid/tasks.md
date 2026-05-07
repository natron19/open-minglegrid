# MingleGrid Demo — Build Task Tracker

Built on: Open Demo Starter v2.0  
Spec: [`docs/open-minglegrid/minglegrid-demo-spec.md`](minglegrid-demo-spec.md)  
Reference guides: `docs/ai-templates.md`, `docs/ai-guardrails.md`, `docs/testing.md`, `docs/turbo-stimulus-patterns.md`

**Legend:** `[ ]` to-do · `[x]` done · `[~]` in progress

Each phase has a dedicated spec file with full implementation details, RSpec coverage, and manual checks.

---

## Phase 1 — Boilerplate Configuration
**Spec:** [phase_1_boilerplate_config.md](phase_1_boilerplate_config.md)

- [x] `.env.example` updated with MingleGrid values (APP_NAME, APP_TAGLINE, APP_DESCRIPTION, AI_CALLS_PER_USER_PER_DAY=20)
- [x] Local `.env` updated to match
- [x] CSS custom properties added (--accent, --accent-hover, --accent-secondary, .bg-accent)
- [x] "Groups" nav link added to application layout (auth-gated)
- [x] `home/index.html.erb` replaced with MingleGrid landing page
- [x] `dashboard/show.html.erb` replaced with "Go to your groups" panel

---

## Phase 2 — Data Models
**Spec:** [phase_2_data_models.md](phase_2_data_models.md)

- [x] Migration: `support_groups`
- [x] Migration: `group_charters`
- [x] Migration: `launch_sessions`
- [x] Migration: `add_scheduling_to_launch_sessions` (scheduled_at, completed_at)
- [x] `rails db:migrate` clean
- [x] `SupportGroup` model with validations, associations, constants
- [x] `GroupCharter` model with serialization helpers
- [x] `LaunchSession` model with validations + `completed?` helper
- [x] Factories: `support_groups`, `group_charters`, `launch_sessions`
- [x] `spec/models/support_group_spec.rb` — all pass
- [x] `spec/models/group_charter_spec.rb` — all pass
- [x] `spec/models/launch_session_spec.rb` — all pass

---

## Phase 3 — Support Groups CRUD
**Spec:** [phase_3_support_groups_crud.md](phase_3_support_groups_crud.md)

- [x] Routes added to `config/routes.rb`
- [x] `SupportGroupsController` with all actions
- [x] `support_groups/index.html.erb` (card grid + empty state)
- [x] `support_groups/_card.html.erb` partial
- [x] `support_groups/new.html.erb` and `edit.html.erb`
- [x] `support_groups/_form.html.erb` with all fields
- [x] `support_groups/show.html.erb` (three regions, charter placeholder)
- [x] `spec/requests/support_groups_spec.rb` — all pass

---

## Phase 4 — Charter Parser Service
**Spec:** [phase_4_charter_parser.md](phase_4_charter_parser.md)

- [x] `app/services/charter_parser.rb` — full implementation
- [x] `spec/services/charter_parser_spec.rb` — all pass
- [x] `spec/fixtures/files/sample_grief_circle_response.json` — valid fixture created

---

## Phase 5 — AI Integration
**Spec:** [phase_5_ai_integration.md](phase_5_ai_integration.md)

- [x] `minglegrid_charter_v1` template seeded (`rails db:seed`)
- [x] `ChartersController` — create, regenerate (with optional session preservation), print actions
- [x] `LaunchSessionsController` — update (schedule + complete toggle)
- [x] Rate limiting on charter endpoints
- [x] `layouts/print.html.erb` created
- [x] `charters/_generate_cta.html.erb` with Turbo Frame + spinner loading state + cancel
- [x] `charters/_charter_card.html.erb` with regenerate form + sessions checkbox
- [x] `charters/_session_card.html.erb` — vertical accordion with schedule and complete
- [x] `charters/_boundary_panel.html.erb`
- [x] `support_groups/show.html.erb` updated (turbo_frame_tag "charter-region")
- [x] `charters/print.html.erb`
- [x] `charter_loading_controller.js` — Stimulus controller for generation animation
- [x] `spec/requests/charters_spec.rb` — all pass
- [x] `spec/requests/charters_print_spec.rb` — all pass

---

## Phase 6 — Seeds and Sample Data
**Spec:** [phase_6_seeds.md](phase_6_seeds.md)

- [x] Three sample `SupportGroup` records in `db/seeds.rb`
- [x] Tuesday Grief Circle fully populated with charter + 4 sessions from fixture
- [x] Seeds are idempotent (`rails db:seed` twice = no errors, no duplicates)
- [x] Full RSpec suite passes after seeding

---

## Phase 7 — Visual Polish and Print Styles
**Spec:** [phase_7_visual_polish.md](phase_7_visual_polish.md)

- [x] `app/assets/stylesheets/minglegrid.css` created (boundary panel, session accordion, card hover, print styles)
- [x] `minglegrid.css` linked in application layout and print layout
- [x] CSS classes applied in all relevant views
- [x] Active nav link style for "Groups"
- [x] Manual visual checks pass

---

## Phase 8 — README Updates
**Spec:** [phase_8_readme.md](phase_8_readme.md)

- [x] `README.md` header replaced with MingleGrid content
- [x] "Why I Built This" section added
- [x] "Editing the AI Prompt" section added
- [x] Demo credentials, stack, and AI safety sections confirmed accurate
- [x] No boilerplate placeholder text remains

---

## Phase 9 — Final Verification
**Spec:** [phase_9_final_verification.md](phase_9_final_verification.md)

- [x] `bundle exec rspec` — 202 examples, 0 failures, 0 real Gemini calls
- [x] Pre-publish security check completed — all automated checks pass
- [x] `your-handle` footer placeholder removed
- [ ] Full end-to-end manual test on fresh database
- [ ] All security checklist items resolved

---

## Summary

| Phase | Description | Status |
|---|---|---|
| 1 | Boilerplate Configuration | [x] |
| 2 | Data Models | [x] |
| 3 | Support Groups CRUD | [x] |
| 4 | Charter Parser Service | [x] |
| 5 | AI Integration | [x] |
| 6 | Seeds and Sample Data | [x] |
| 7 | Visual Polish and Print Styles | [x] |
| 8 | README Updates | [x] |
| 9 | Final Verification | [ ] |
