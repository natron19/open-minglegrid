# Phase 1 — Boilerplate Configuration

**App:** MingleGrid Demo (built on Open Demo Starter v2.0)  
**Goal:** Configure the generic starter for MingleGrid-specific branding, colors, and navigation. No domain models are created in this phase.  
**Spec reference:** [`minglegrid-demo-spec.md`](minglegrid-demo-spec.md) — Sections 1, 2, 12  
**Depends on:** Open Demo Starter v2.0 base app is running locally (`rails server` starts, `GET /` returns 200)  
**Next phase:** [phase_2_data_models.md](phase_2_data_models.md)

**Before starting, read:**
- `CLAUDE.md` — especially the rules on env vars, Stimulus-only JS, and no SCSS compilation (Propshaft = plain CSS)
- `docs/turbo-stimulus-patterns.md` — if touching any JavaScript-adjacent view work

---

## Tasks

### 1.1 — Update `.env.example`

Set these values (all are placeholders — no real secrets):

```
APP_NAME=MingleGrid Demo
APP_TAGLINE=Describe your support group. Get a charter and a 4-session startup plan.
APP_DESCRIPTION=MingleGrid Demo turns a short description of a peer support group into a printable charter, a four-session launch sequence, and two facilitator boundary reminders.
AI_CALLS_PER_USER_PER_DAY=20
```

The tightened daily cap (20 vs. the 50 default) is intentional — charter generation is deliberate, not high-frequency. See spec Section 8.

### 1.2 — Update local `.env`

Copy the new values from `.env.example` into your local `.env`. Never commit `.env`.

### 1.3 — CSS custom properties

Add to `app/assets/stylesheets/application.css` (plain `.css` — this is a Propshaft project, no SCSS):

```css
:root {
  --accent: #fdba74;
  --accent-hover: #fb923c;
  --accent-secondary: #93c5fd;
}

.bg-accent {
  background-color: var(--accent) !important;
  color: #1a1a1a !important;
}

a {
  color: var(--accent);
}

a:hover {
  color: var(--accent-hover);
}
```

- `--accent` (warm orange) is used for primary buttons and active nav states.
- `--accent-secondary` (soft blue) is used only for the boundary reminders panel. This visual separation is intentional: orange = action, blue = caution.

### 1.4 — Add "Groups" nav link

In `app/views/layouts/application.html.erb`, add a "Groups" link to the navbar. Place it after the dashboard link, before the user dropdown. It should only appear when signed in:

```erb
<% if signed_in? %>
  <%= link_to "Groups", support_groups_path, class: "nav-link" %>
<% end %>
```

The `support_groups_path` route doesn't exist yet — it will be added in Phase 3. The link will raise a routing error if clicked before Phase 3 is complete; that's acceptable at this stage.

### 1.5 — Replace landing page

Replace `app/views/home/index.html.erb` with the MingleGrid landing page. Three regions:

**Hero:**
```erb
<div class="container py-5 text-center">
  <h1 class="display-4 fw-bold"><%= ENV.fetch("APP_NAME", "MingleGrid Demo") %></h1>
  <p class="lead"><%= ENV.fetch("APP_TAGLINE", "") %></p>
  <%= link_to "Sign up to start", sign_up_path, class: "btn btn-lg bg-accent mt-3" %>
</div>
```

**Three-column "How it works":**
```erb
<div class="container pb-5">
  <div class="row g-4 text-center">
    <div class="col-md-4">
      <h5>1. Describe</h5>
      <p>Fill in your group's purpose, meeting cadence, and host organization.</p>
    </div>
    <div class="col-md-4">
      <h5>2. Generate</h5>
      <p>Gemini returns a S.A.F.E. charter, a four-session launch plan, and two boundary reminders.</p>
    </div>
    <div class="col-md-4">
      <h5>3. Print</h5>
      <p>Take the charter to your first meeting. Use the boundary reminders when conversation drifts.</p>
    </div>
  </div>
</div>
```

All copy must use `ENV.fetch(...)` for app name and tagline — never hardcode.

### 1.6 — Replace dashboard

Replace `app/views/dashboard/show.html.erb` with a thin wrapper panel that points users to their groups:

```erb
<div class="container py-4">
  <h1>Welcome back</h1>
  <p class="text-muted">Your groups are the main event. Head there to generate or review a charter.</p>
  <%= link_to "Go to your groups →", support_groups_path, class: "btn bg-accent" %>
</div>
```

The `support_groups_path` route doesn't exist yet — same acceptable state as 1.4.

---

## Manual Checks — Phase 1

Run these manually in the browser before moving to Phase 2.

- [ ] Visit `/` — landing page shows tagline and three-step explainer; no boilerplate placeholder text
- [ ] `APP_NAME` in the navbar reads "MingleGrid Demo" (pulled from env, not hardcoded)
- [ ] Visit `/dashboard` after signing in — sees the "Go to your groups" panel, not the old boilerplate dashboard
- [ ] Navbar shows "Groups" link only when signed in; does not appear on the public landing page
- [ ] Accent color (`#fdba74`, warm orange) is visible on at least one button
- [ ] Anchor links use the accent orange color (not Bootstrap's default blue)
- [ ] No SCSS compilation errors — Propshaft serves plain CSS without a build step

### No RSpec in This Phase

Phase 1 changes are all config, CSS, and ERB. RSpec coverage begins in Phase 2 (model specs) and Phase 3 (request specs). If you want to verify ENV var behavior, do it in the Rails console:

```ruby
ENV.fetch("APP_NAME", "Open Demo Starter")
# => "MingleGrid Demo"
```
