# MingleGrid Demo

> Describe your support group. Get a charter and a 4-session startup plan.

MingleGrid Demo turns a short description of a peer support group into a
printable charter, a four-session launch sequence, and two facilitator
boundary reminders. It is a single-feature, locally-runnable Rails 8 app
built on the Open Demo Starter v2.0.

## Screenshots

See `docs/screenshots/`. Replace with your own captures when forking.

## Why I Built This

I am building a multi-tenant SaaS suite for community work, and MingleGrid is
the peer support tool in that suite. The full version handles organizations,
member rolls, recurring scheduling, and group health checks. This open source
demo isolates the most useful 60 seconds of that experience: turning a brief
into a charter you can take to the first meeting.

The full product lives at https://minglegrid.app (placeholder). This repo is
MIT licensed; clone it, run it, change the prompt, and see how a small Rails 8
app plus Gemini plus a tight template handles a sensitive domain.

## Setup

1. Clone the repo
2. Run `bin/setup` (creates the database, runs migrations, copies `.env.example` to `.env`)
3. Add your `GEMINI_API_KEY` to `.env`
4. Run `rails db:seed`
5. Run `bin/dev` or `rails server`
6. Visit `http://localhost:3000`

## Demo Credentials

Email: `demo@example.com`  
Password: `password123`  
Role: admin (can access `/admin`)

## Editing the AI Prompt

The prompt is data, not code. Sign in as `demo@example.com` / `password123`
(seeded admin), open `/admin/ai_templates`, and click into
`minglegrid_charter_v1` to edit the system prompt, user prompt template,
model, max tokens, and temperature. The right-side test panel runs the live
draft against Gemini without saving so you can iterate. Save when satisfied.

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Asset Pipeline | Propshaft (no Sprockets, no Webpack) |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini via `gemini-ai` gem |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"MingleGrid Demo"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer |
| `APP_DESCRIPTION` | — | Shown on the landing page |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key — get one free at https://aistudio.google.com/app/apikey |
| `AI_CALLS_PER_USER_PER_DAY` | `20` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `15` | Gemini request timeout in seconds |

## AI Safety Posture

**What this app enforces:**
- Per-user daily call cap (default: 20/day, set via `AI_CALLS_PER_USER_PER_DAY`)
- Clinical refusal path in the system prompt: if the group description suggests an acute clinical context (active suicidality, court-ordered treatment, medication management), Gemini returns a structured refusal rather than generating a charter
- Inline disclaimer on every group show page reminding users this is a peer support tool, not a clinical treatment plan
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap (3000 tokens) and configurable timeout (default: 15s)
- Full request log with status, tokens, duration, and cost estimate
- Fail-soft UI: errors render inline, never crash the page
- AI disclaimer in the footer on every page

**Deliberately omitted:**
- No member-facing experience — this tool is for group organizers, not members
- No clinical language in the charter output — the system prompt enforces plain peer-support prose
- No named members, session attendance tracking, or PII storage
- No automatic retries — avoids stacking costs on transient failures
- No RAG or vector DB — single-shot prompts only
- No streaming — synchronous calls keep the code simple

See `app/services/ai_gatekeeper.rb`, `app/services/ai_budget_checker.rb`, and
the `minglegrid_charter_v1` template in `/admin/ai_templates` for details.

## License

MIT — see [LICENSE](LICENSE)
