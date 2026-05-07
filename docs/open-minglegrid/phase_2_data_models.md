# Phase 2 — Data Models

**App:** MingleGrid Demo (built on Open Demo Starter v2.0)  
**Goal:** Create the three domain models — `SupportGroup`, `GroupCharter`, `LaunchSession` — with migrations, validations, associations, factories, and full model specs.  
**Spec reference:** [`minglegrid-demo-spec.md`](minglegrid-demo-spec.md) — Section 3  
**Depends on:** Phase 1 complete; database running with `pgcrypto` extension enabled  
**Next phase:** [phase_3_support_groups_crud.md](phase_3_support_groups_crud.md)

**Before starting, read:**
- `CLAUDE.md` — database conventions (UUID PKs, null: false timestamps, pgcrypto, foreign key types)
- `docs/testing.md` — factory conventions and model spec patterns

---

## Tasks

### 2.1 — Migration: `support_groups`

```ruby
create_table :support_groups, id: :uuid do |t|
  t.references :user, null: false, foreign_key: true, type: :uuid
  t.string  :name,                    null: false
  t.text    :purpose,                 null: false
  t.text    :target_demographics
  t.string  :meeting_cadence,         null: false
  t.integer :session_length_minutes,  null: false
  t.string  :organization_type,       null: false
  t.timestamps null: false
end
add_index :support_groups, :user_id
add_index :support_groups, :updated_at
```

### 2.2 — Migration: `group_charters`

```ruby
create_table :group_charters, id: :uuid do |t|
  t.references :support_group, null: false, foreign_key: true, type: :uuid, index: { unique: true }
  t.text :purpose_statement
  t.text :meeting_structure
  t.text :member_commitments
  t.text :agreements
  t.text :boundary_reminders
  t.text :gemini_raw
  t.datetime :generated_at
  t.timestamps null: false
end
```

`agreements` and `boundary_reminders` are stored as JSON array strings (plain `text` column, no `jsonb`). The model provides helpers that parse them.

### 2.3 — Migration: `launch_sessions`

```ruby
create_table :launch_sessions, id: :uuid do |t|
  t.references :group_charter, null: false, foreign_key: true, type: :uuid
  t.integer :session_number, null: false
  t.string  :title,             null: false
  t.text    :check_in_format,   null: false
  t.text    :discussion_topic,  null: false
  t.text    :activity,          null: false
  t.text    :closing_ritual,    null: false
  t.timestamps null: false
end
add_index :launch_sessions, [:group_charter_id, :session_number], unique: true
```

### 2.4 — Run migrations

```bash
rails db:migrate
```

### 2.5 — `app/models/support_group.rb`

```ruby
class SupportGroup < ApplicationRecord
  belongs_to :user
  has_one :group_charter, dependent: :destroy

  MEETING_CADENCES   = %w[weekly biweekly monthly].freeze
  ORGANIZATION_TYPES = %w[faith_community nonprofit workplace online_cohort other].freeze

  validates :name,                   presence: true, length: { in: 2..80 }
  validates :purpose,                presence: true, length: { in: 20..1000 }
  validates :target_demographics,    length: { maximum: 500 }, allow_blank: true
  validates :meeting_cadence,        presence: true, inclusion: { in: MEETING_CADENCES }
  validates :session_length_minutes, presence: true, inclusion: { in: 30..180 }
  validates :organization_type,      presence: true, inclusion: { in: ORGANIZATION_TYPES }
end
```

### 2.6 — `app/models/group_charter.rb`

```ruby
class GroupCharter < ApplicationRecord
  belongs_to :support_group
  has_one :user, through: :support_group
  has_many :launch_sessions, dependent: :destroy

  validates :support_group_id, uniqueness: true
  validates :gemini_raw, presence: true

  def agreements_list
    JSON.parse(agreements || "[]")
  rescue JSON::ParserError
    []
  end

  def boundary_reminders_list
    JSON.parse(boundary_reminders || "[]")
  rescue JSON::ParserError
    []
  end
end
```

### 2.7 — `app/models/launch_session.rb`

```ruby
class LaunchSession < ApplicationRecord
  belongs_to :group_charter
  has_one :support_group, through: :group_charter

  validates :session_number,    presence: true, inclusion: { in: 1..4 }
  validates :session_number,    uniqueness: { scope: :group_charter_id }
  validates :title,             presence: true
  validates :check_in_format,   presence: true
  validates :discussion_topic,  presence: true
  validates :activity,          presence: true
  validates :closing_ritual,    presence: true
end
```

### 2.8 — Factories

**`spec/factories/support_groups.rb`:**

```ruby
FactoryBot.define do
  factory :support_group do
    association :user
    name                    { "Tuesday Grief Circle" }
    purpose                 { "Peer support for adults grieving a spouse or parent in their first year of loss." }
    target_demographics     { "Adults over 40 in a small congregation." }
    meeting_cadence         { "weekly" }
    session_length_minutes  { 90 }
    organization_type       { "faith_community" }

    trait :with_charter do
      after(:create) do |group|
        charter = create(:group_charter, support_group: group)
        create_list(:launch_session, 4, :sequential, group_charter: charter)
      end
    end
  end
end
```

**`spec/factories/group_charters.rb`:**

```ruby
FactoryBot.define do
  factory :group_charter do
    association :support_group
    purpose_statement   { "This group provides structured peer support for adults navigating early grief." }
    meeting_structure   { "Each meeting opens with a brief check-in, moves into a discussion topic, and closes with a shared reflection." }
    member_commitments  { "Members agree to attend regularly, hold each other's stories in confidence, and refrain from giving unsolicited advice." }
    agreements          { '["Confidentiality: what is shared here stays here.", "No advice unless asked.", "One voice at a time.", "It is okay to pass."]' }
    boundary_reminders  { '["If what you are describing sounds like it needs more than peer support can hold, I can help you find a counselor.", "This is a peer group, not therapy. If you are in crisis, please call 988."]' }
    gemini_raw          { agreements }
    generated_at        { Time.current }
  end
end
```

**`spec/factories/launch_sessions.rb`:**

```ruby
FactoryBot.define do
  factory :launch_session do
    association :group_charter
    session_number    { 1 }
    title             { "Trust Building" }
    check_in_format   { "Each member shares one word describing how they arrived today." }
    discussion_topic  { "What brought you to this group, and what do you hope to find here?" }
    activity          { "Pair sharing: partners take three minutes each to share without interruption." }
    closing_ritual    { "A moment of silence followed by one word each for how you are leaving." }

    trait :sequential do
      sequence(:session_number) { |n| n }
      title { "Session #{session_number}" }
    end
  end
end
```

---

## RSpec — Phase 2

Run after completing all tasks above:

```bash
bundle exec rspec spec/models/
```

### `spec/models/support_group_spec.rb`

Cover:
- Valid factory creates without errors
- `name` presence and length (min 2, max 80)
- `purpose` presence and length (min 20, max 1000)
- `target_demographics` is optional; max 500 chars
- `meeting_cadence` presence and inclusion in `MEETING_CADENCES`
- `organization_type` presence and inclusion in `ORGANIZATION_TYPES`
- `session_length_minutes` presence and inclusion in 30..180
- `belongs_to :user` — nil user is invalid
- `has_one :group_charter` — association loads correctly
- Destroying a `SupportGroup` cascades to `GroupCharter` and all `LaunchSession` records

### `spec/models/group_charter_spec.rb`

Cover:
- Valid factory creates without errors
- `support_group_id` uniqueness — a second charter for the same group is invalid
- `gemini_raw` presence — blank is invalid
- `has_many :launch_sessions, dependent: :destroy` — verified by destroying charter and confirming sessions gone
- `agreements_list` parses a valid JSON array and returns `Array<String>`
- `boundary_reminders_list` parses a valid JSON array and returns `Array<String>`
- Both helpers return `[]` gracefully when field is nil or malformed JSON

### `spec/models/launch_session_spec.rb`

Cover:
- Valid factory creates without errors
- `session_number` inclusion in 1..4 — 0 and 5 are invalid
- `session_number` uniqueness scoped to `group_charter_id` — duplicate session number on same charter is invalid
- `title`, `check_in_format`, `discussion_topic`, `activity`, `closing_ritual` all presence validated

---

## Manual Checks — Phase 2

- [ ] `rails db:migrate` runs cleanly with no errors and no skipped steps
- [ ] Rails console: `SupportGroup.new` responds without error; `SupportGroup.new.valid?` returns false with expected errors
- [ ] Rails console: `create(:support_group)` (via factory) succeeds in test environment
- [ ] Rails console: destroying a `SupportGroup` that has a charter also destroys the charter and all sessions (verify counts before and after)
- [ ] `bundle exec rspec spec/models/` — all model specs pass, zero failures
