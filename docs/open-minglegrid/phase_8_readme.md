# Phase 8 — README Updates

**App:** MingleGrid Demo (built on Open Demo Starter v2.0)  
**Goal:** Replace boilerplate README placeholder content with MingleGrid-specific content. The README is what a portfolio reviewer or open source contributor reads first.  
**Spec reference:** [`minglegrid-demo-spec.md`](minglegrid-demo-spec.md) — Section 11  
**Depends on:** Phases 1–7 complete — the app is functionally done; README should describe what was actually built  
**Next phase:** [phase_9_final_verification.md](phase_9_final_verification.md)

**No RSpec in this phase.** README accuracy is verified by manual review.

---

## Tasks

### 8.1 — Update `README.md`

Replace the boilerplate header block with:

```markdown
# MingleGrid Demo

> Describe your support group. Get a charter and a 4-session startup plan.

MingleGrid Demo turns a short description of a peer support group into a
printable charter, a four-session launch sequence, and two facilitator
boundary reminders. It is a single-feature, locally-runnable Rails 8 app
built on the Open Demo Starter v2.0.
```

### 8.2 — Screenshot placeholder section

Add after the intro paragraph:

```markdown
## Screenshots

See `docs/screenshots/`. Replace with your own captures when forking.
```

### 8.3 — "Why I Built This" section

```markdown
## Why I Built This

I am building a multi-tenant SaaS suite for community work, and MingleGrid is
the peer support tool in that suite. The full version handles organizations,
member rolls, recurring scheduling, and group health checks. This open source
demo isolates the most useful 60 seconds of that experience: turning a brief
into a charter you can take to the first meeting.

The full product lives at https://minglegrid.app (placeholder). This repo is
MIT licensed; clone it, run it, change the prompt, and see how a small Rails 8
app plus Gemini plus a tight template handles a sensitive domain.
```

### 8.4 — "Editing the AI Prompt" section

```markdown
## Editing the AI Prompt

The prompt is data, not code. Sign in as `demo@example.com` / `password123`
(seeded admin), open `/admin/ai_templates`, and click into
`minglegrid_charter_v1` to edit the system prompt, user prompt template,
model, max tokens, and temperature. The right-side test panel runs the live
draft against Gemini without saving so you can iterate. Save when satisfied.
```

### 8.5 — Confirm required sections are present and accurate

Check that these sections exist and are accurate (they may already be in the boilerplate README):

**Stack section** — must reflect the actual stack:
- Rails 8.1, PostgreSQL, UUID PKs
- Bootstrap 5 dark mode (CDN)
- Stimulus + Turbo via importmap
- Propshaft (not Sprockets or Webpack)
- Gemini via `gemini-ai` gem
- RSpec

**Setup section** — must match the actual setup flow:

```markdown
## Setup

1. Clone the repo
2. Run `bin/setup` (creates the database, runs migrations, copies `.env.example` to `.env`)
3. Add your `GEMINI_API_KEY` to `.env`
4. Run `rails db:seed`
5. Run `bin/dev` or `rails server`
6. Visit `http://localhost:3000`
```

**Demo credentials section** — must list:

```markdown
## Demo Credentials

Email: `demo@example.com`  
Password: `password123`  
Role: admin (can access `/admin`)
```

**AI Safety Posture section** — must include:
- The clinical refusal path in the system prompt
- The inline disclaimer on the show page
- The tightened `AI_CALLS_PER_USER_PER_DAY=20` setting
- What the app deliberately does NOT do (member-facing experience, clinical language, named members)

---

## Manual Checks — Phase 8

- [ ] `README.md` header reads "# MingleGrid Demo" — no boilerplate title remains
- [ ] Intro paragraph describes what the app does in plain language
- [ ] "Why I Built This" section is present and accurate
- [ ] "Editing the AI Prompt" section correctly describes the `/admin/ai_templates` workflow
- [ ] Stack section reflects the actual stack (Propshaft, not Sprockets; `gemini-ai` gem, not `google-generative-ai`)
- [ ] Demo credentials are listed: `demo@example.com` / `password123`
- [ ] AI safety posture section mentions the clinical refusal path and the inline disclaimer
- [ ] No placeholder text from the boilerplate template remains (search for "Open Demo Starter" and "TODO" in README)
- [ ] Preview the README in a Markdown renderer (VS Code preview, GitHub, or `gh markdown-preview`) — formatting looks clean, no broken links
