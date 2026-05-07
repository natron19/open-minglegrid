# Phase 7 — Visual Polish and Print Styles

**App:** MingleGrid Demo (built on Open Demo Starter v2.0)  
**Goal:** Add custom CSS for the boundary reminder panel, session scroll behavior, card hover states, and print styles. Apply CSS classes in all views that need them.  
**Spec reference:** [`minglegrid-demo-spec.md`](minglegrid-demo-spec.md) — Section 12  
**Depends on:** Phase 5 complete — all views and partials exist and reference the CSS classes  
**Next phase:** [phase_8_readme.md](phase_8_readme.md)

**Before starting, read:**
- `CLAUDE.md` — Propshaft rule: no SCSS compilation; plain `.css` files only; no build step needed

**No RSpec in this phase.** CSS correctness is verified through manual browser checks. The session scroll, collapse behavior, and print output cannot be meaningfully tested with request specs.

---

## Tasks

### 7.1 — Create `app/assets/stylesheets/minglegrid.css`

Plain CSS. No SCSS, no `@import` from other files, no build step. Propshaft serves this file automatically. Total must stay under 80 lines.

```css
/* Boundary reminder panel */
.boundary-panel {
  border: 1px dashed var(--accent-secondary);
  border-radius: 6px;
  padding: 1rem;
  background-color: rgba(147, 197, 253, 0.05);
}

.boundary-panel .reminder-text::before {
  content: "\201C";
  color: var(--accent-secondary);
  font-size: 1.2em;
  margin-right: 0.25rem;
}

/* Session card horizontal scroll */
.session-scroll {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  gap: 1rem;
  padding-bottom: 0.5rem;
}

.session-scroll .session-card {
  flex: 0 0 320px;
  scroll-snap-align: start;
}

/* Card hover state (used on group index cards) */
.card-hover {
  transition: border-color 0.15s ease;
  border: 1px solid transparent;
}

.card-hover:hover {
  border-color: var(--accent);
}

/* Session number badge */
.session-badge {
  background-color: var(--accent);
  color: #1a1a1a;
  font-weight: 600;
  border-radius: 4px;
  padding: 0.15em 0.5em;
  font-size: 0.8rem;
}

/* Print styles */
@media print {
  .navbar, .btn, .alert-dismissible .btn-close {
    display: none !important;
  }

  body {
    background: white !important;
    color: black !important;
    font-size: 12pt;
  }

  .session-scroll {
    display: block;
    overflow: visible;
  }

  .session-card {
    page-break-inside: avoid;
    margin-bottom: 1rem;
  }

  .charter-disclaimer {
    page-break-before: always;
  }
}
```

### 7.2 — Link `minglegrid.css` in the application layout

Propshaft serves all files in `app/assets/stylesheets` automatically, but the layout must include a `<link>` tag:

In `app/views/layouts/application.html.erb`, add after the existing `stylesheet_link_tag`:

```erb
<%= stylesheet_link_tag "minglegrid" %>
```

Also add it to `layouts/print.html.erb` (already included if you followed Phase 5 exactly).

### 7.3 — Apply CSS classes in views

Verify these classes are applied in the correct partials and views. Add them if missing:

| CSS class | Where to apply |
|---|---|
| `.card-hover` | `support_groups/_card.html.erb` — on the outer `<div class="card">` |
| `.session-scroll` | `support_groups/show.html.erb` — on the container `<div>` that wraps session cards |
| `.session-card` | `charters/_session_card.html.erb` — on the outer `<div class="card">` |
| `.session-badge` | `charters/_session_card.html.erb` — on the "Session N" `<span>` |
| `.boundary-panel` | `charters/_boundary_panel.html.erb` — on the outer container |
| `.reminder-text` | `charters/_boundary_panel.html.erb` — on each boundary reminder `<p>` |
| `.charter-disclaimer` | `charters/print.html.erb` — on the disclaimer `<div>` at the bottom |

### 7.4 — Active navbar link state for "Groups"

In `app/views/layouts/application.html.erb`, add Bootstrap's `.active` class to the "Groups" link when the current path starts with `/support_groups`:

```erb
<%= link_to "Groups", support_groups_path,
    class: "nav-link #{'active' if request.path.start_with?('/support_groups')}" %>
```

---

## Manual Checks — Phase 7

Run all checks in the browser after completing the tasks above.

- [ ] Groups index: hover over a group card — a subtle accent-orange border appears; border disappears on mouse-out
- [ ] Group show page (Tuesday Grief Circle): the session cards region scrolls horizontally; each card snaps to position when scrolled; all four session cards are reachable
- [ ] Each session card shows the warm-orange "Session N" badge
- [ ] Expanding a session card (click header) reveals the four prose fields; collapsing hides them; Bootstrap collapse works correctly
- [ ] Boundary reminders panel: dashed soft-blue border, slight blue tint background, curly quote glyph appears before each reminder
- [ ] Print the charter (`Ctrl+P` or `Cmd+P` on the print page) — navbar and buttons are hidden; layout is clean black-on-white; session cards display as a block list (not horizontal scroll); disclaimer has a page break before it
- [ ] "Groups" nav link is visually highlighted (Bootstrap `.active` class) when on any `/support_groups` path; not highlighted on other pages
- [ ] `minglegrid.css` file line count: `wc -l app/assets/stylesheets/minglegrid.css` — should be under 80
- [ ] No SCSS compilation errors or Propshaft warnings in `rails server` output
