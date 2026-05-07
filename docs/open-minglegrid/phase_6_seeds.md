# Phase 6 — Seeds and Sample Data

**App:** MingleGrid Demo (built on Open Demo Starter v2.0)  
**Goal:** Populate the database with realistic demo data so first-time visitors immediately see a working example — one fully-chartered group and two "Generate charter" call-to-action groups.  
**Spec reference:** [`minglegrid-demo-spec.md`](minglegrid-demo-spec.md) — Section 10  
**Depends on:** Phase 5 complete — `ChartersController` exists, `CharterParser` exists, and the `sample_grief_circle_response.json` fixture is in place  
**Next phase:** [phase_7_visual_polish.md](phase_7_visual_polish.md)

**Before starting, read:**
- `CLAUDE.md` — seed credentials: always `demo@example.com` / `password123`; use `find_or_create_by!` for idempotency

---

## Tasks

### 6.1 — Extend `db/seeds.rb` with three sample groups

The seed file already creates the `demo@example.com` admin user and the `minglegrid_charter_v1` template (added in Phase 5). Extend it with the three domain seed groups. All use `find_or_create_by!` so `rails db:seed` is safe to run multiple times.

```ruby
demo_user = User.find_by!(email: "demo@example.com")

grief_circle = SupportGroup.find_or_create_by!(user: demo_user, name: "Tuesday Grief Circle") do |g|
  g.purpose               = "Peer support for adults in the first year of grieving a spouse or parent. The group provides structured companionship and a safe space to process loss without unsolicited advice or grief timelines."
  g.target_demographics   = "Adults over 40 in a small congregation navigating recent bereavement."
  g.meeting_cadence       = "weekly"
  g.session_length_minutes = 90
  g.organization_type     = "faith_community"
end

SupportGroup.find_or_create_by!(user: demo_user, name: "New Manager Cohort") do |g|
  g.purpose               = "Peer support and skill-sharing for first-time engineering managers in their first six months in role. Participants share common challenges, get candid feedback, and avoid the isolation that often accompanies a first management role."
  g.target_demographics   = "Engineering managers at a mid-sized tech company, all within six months of their first management role."
  g.meeting_cadence       = "biweekly"
  g.session_length_minutes = 60
  g.organization_type     = "workplace"
end

SupportGroup.find_or_create_by!(user: demo_user, name: "Sober Curious Online") do |g|
  g.purpose               = "Peer support for people exploring a 90-day break from alcohol without committing to a recovery program identity. The group normalizes curiosity without requiring abstinence identity."
  g.target_demographics   = "Adults across multiple time zones who are questioning their relationship with alcohol but not ready to label it."
  g.meeting_cadence       = "weekly"
  g.session_length_minutes = 60
  g.organization_type     = "online_cohort"
end
```

### 6.2 — Create a fully-populated charter for Tuesday Grief Circle

Use the fixture file from Phase 4 to build the charter without making a real Gemini API call.

```ruby
unless grief_circle.group_charter.present?
  raw = File.read(Rails.root.join("spec/fixtures/files/sample_grief_circle_response.json"))
  data = CharterParser.new(raw).parse!

  ActiveRecord::Base.transaction do
    charter = grief_circle.create_group_charter!(
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
```

The `unless grief_circle.group_charter.present?` guard ensures re-running seeds never double-creates the charter.

### 6.3 — Run and verify

```bash
rails db:seed
```

Then run again to confirm idempotency:

```bash
rails db:seed
```

Both runs should complete with no errors, no duplicate records, and no duplicate charter records.

---

## RSpec — Phase 6

There are no new spec files in this phase. Seeding is verified by running the full suite to confirm that seed helper code (CharterParser, model associations) remains correct end-to-end:

```bash
bundle exec rspec spec/models/ spec/services/ spec/requests/
```

All specs written in Phases 2–5 should continue to pass. If any fail after seeding, it indicates a seed interaction with the test database (check that seeds only target the development database and that specs use the test database with `DatabaseCleaner` or transactional fixtures).

---

## Manual Checks — Phase 6

- [ ] `rails db:seed` completes with no errors
- [ ] Sign in as `demo@example.com` / `password123`
- [ ] Groups index shows exactly three cards:
  - "Tuesday Grief Circle" with green "Charter ready" badge
  - "New Manager Cohort" with muted "No charter yet" badge
  - "Sober Curious Online" with muted "No charter yet" badge
- [ ] Tuesday Grief Circle show page displays: charter card with all sections, four session cards in horizontal scroll, boundary reminders in sidebar, "Show raw response" toggle works
- [ ] New Manager Cohort show page shows the "Generate charter" CTA with disclaimer
- [ ] Running `rails db:seed` a second time produces no error and no duplicate groups (check `SupportGroup.count` in console — still 3)
- [ ] Running `rails db:seed` a second time does not create a second charter for Tuesday Grief Circle (check `GroupCharter.count` — still 1)
- [ ] `bundle exec rspec spec/models/ spec/services/ spec/requests/` — full suite passes
