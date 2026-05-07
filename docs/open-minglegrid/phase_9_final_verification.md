# Phase 9 — Final Verification

**App:** MingleGrid Demo (built on Open Demo Starter v2.0)  
**Goal:** Confirm the full app works end-to-end on a fresh database, the RSpec suite is clean, and the app is safe to publish publicly on GitHub.  
**Depends on:** Phases 1–8 complete  
**This is the last phase.**

---

## Step 1 — Full RSpec Suite

```bash
bundle exec rspec
```

Requirements:
- Zero failures
- Zero pending or skipped examples (or document why any are intentionally pending)
- Zero real Gemini API calls during the run — check the test log for any HTTP requests to `googleapis.com`

```bash
bundle exec rspec --format documentation
```

Review the output. Every example name should be intelligible. Flag and fix any that are vague (e.g., "works" or "is valid").

---

## Step 2 — End-to-End Manual Test (fresh database)

Reset to a clean state:

```bash
rails db:drop db:create db:migrate db:seed
```

Then run through this checklist in the browser:

### Seeded state
- [ ] Sign in as `demo@example.com` / `password123`
- [ ] Groups index shows three cards: Tuesday Grief Circle (Charter ready), New Manager Cohort (No charter yet), Sober Curious Online (No charter yet)
- [ ] Tuesday Grief Circle show page: charter card with all sections, four session cards in horizontal scroll, boundary reminders in sidebar, "Show raw response" toggle works
- [ ] New Manager Cohort show page: shows "Generate charter" CTA and disclaimer — no charter yet

### CRUD flow
- [ ] Create a brand new group from scratch — form validates all required fields
- [ ] After create, redirected to show page with success flash and the generate CTA visible
- [ ] Generate a charter for the new group — success, all three regions populate correctly
- [ ] Click a session card — expands to show the four prose fields
- [ ] Open the print view — new tab, no navbar, disclaimer at the bottom
- [ ] Regenerate the charter — confirm dialog appears; new charter replaces old one
- [ ] Edit the group — form pre-fills all fields; saving returns to show with success flash
- [ ] Delete the group — confirm dialog; group disappears from index

### Cross-user isolation
- [ ] Sign out and register a completely new account
- [ ] New user's groups index is empty — no cross-user data leakage
- [ ] Manually visit `demo@example.com`'s group show URL while signed in as the new user — returns 404
- [ ] Manually visit `/admin` while signed in as the new user — returns 404 (not 403)

### Admin panel
- [ ] Sign in as `demo@example.com`
- [ ] `/admin` is accessible
- [ ] `/admin/ai_templates` shows `minglegrid_charter_v1`
- [ ] Opening the template and using the test panel returns a valid JSON response from Gemini

---

## Step 3 — Pre-Publish Security Check

Run the full security review from `docs/prompts/pre-publish-security-check.md`. That prompt covers:

1. **Hardcoded secrets** — scan all files for API keys, passwords, tokens
2. **Gitignore coverage** — `.env`, `master.key`, `*.key`, `log/`, `tmp/` are excluded
3. **`.env.example`** — every value is a placeholder, no real values
4. **`config/database.yml`** — no hardcoded credentials; production values use `ENV.fetch`
5. **`db/seeds.rb`** — no hardcoded credentials beyond the documented demo password
6. **`config/environments/production.rb`** — all sensitive values use `ENV.fetch`
7. **Gemfile** — only source is `https://rubygems.org`; no private gem servers
8. **README** — no internal infrastructure details, internal URLs, or real email addresses
9. **Log and tmp files** — `log/` and `tmp/` contain no tracked files with sensitive content
10. **Git history** — no commit message suggests a secret was ever committed

To run the full check, open a new Claude Code conversation and paste the contents of `docs/prompts/pre-publish-security-check.md`. Or run it inline by asking: "Perform the security review described in docs/prompts/pre-publish-security-check.md."

### Security checklist (quick version — verify each manually):

- [ ] `.env` is NOT committed — `git status` shows no `.env` file; `git log --all --full-history -- .env` returns nothing
- [ ] `config/master.key` is NOT committed
- [ ] No hardcoded `APP_NAME`, `APP_TAGLINE`, or branding strings in views — all use `ENV.fetch`
- [ ] No `binding.pry`, `debugger`, or `byebug` in any committed file
- [ ] All forms have CSRF protection (default Rails behavior — confirm it was not disabled)
- [ ] `GET /support_groups/:id` for another user's group returns 404, not 403 or a redirect
- [ ] `GET /admin` for a non-admin returns 404, not 403
- [ ] `.env.example` has no real API keys or passwords — only placeholders like `your_key_here`
- [ ] `db/seeds.rb` only hardcodes the intentional demo password (`password123`), which is documented in the README
- [ ] `git log --oneline` — no commit message mentions "api key", "secret", "token", "credentials", or "password"

---

## Step 4 — Final State Check

Before tagging or publishing:

- [ ] `bundle exec rspec` — zero failures
- [ ] `rails db:drop db:create db:migrate db:seed` — completes without error
- [ ] All manual end-to-end checks above pass
- [ ] All security checklist items are resolved
- [ ] `README.md` has no boilerplate placeholder text
- [ ] `minglegrid.css` is under 80 lines (`wc -l app/assets/stylesheets/minglegrid.css`)
- [ ] The admin test panel returns valid JSON from Gemini (live API call — have your key set)
