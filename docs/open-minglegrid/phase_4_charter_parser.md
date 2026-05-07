# Phase 4 — Charter Parser Service

**App:** MingleGrid Demo (built on Open Demo Starter v2.0)  
**Goal:** Build an isolated Ruby service class that parses Gemini's JSON output into structured data. Pure service logic — no controller or view dependencies.  
**Spec reference:** [`minglegrid-demo-spec.md`](minglegrid-demo-spec.md) — Section 7 (Expected Output Format)  
**Depends on:** Phase 2 complete (models exist and are understood); Phase 3 routes exist  
**Next phase:** [phase_5_ai_integration.md](phase_5_ai_integration.md)

**Before starting, read:**
- `docs/ai-templates.md` — describes the expected JSON schema and GeminiService call flow
- `docs/testing.md` — service spec patterns

This phase has no view or controller changes. It is entirely `app/services/charter_parser.rb` and its spec, plus one fixture file.

---

## Tasks

### 4.1 — `app/services/charter_parser.rb`

```ruby
class CharterParser
  class ParseError < StandardError
    attr_reader :refusal

    def initialize(message, refusal: false)
      super(message)
      @refusal = refusal
    end

    def refusal?
      @refusal
    end
  end

  def initialize(raw)
    @raw = raw.to_s
  end

  def parse!
    json = strip_fences(@raw)
    data = parse_json(json)
    check_refusal(data)
    validate_schema(data)
    data
  end

  private

  def strip_fences(text)
    text.strip.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
  end

  def parse_json(text)
    JSON.parse(text)
  rescue JSON::ParserError => e
    raise ParseError, "Invalid JSON: #{e.message}"
  end

  def check_refusal(data)
    if data.key?("refusal")
      raise ParseError.new(data["refusal"], refusal: true)
    end
  end

  def validate_schema(data)
    validate_string_keys(data)
    validate_agreements(data)
    validate_sessions(data)
    validate_boundary_reminders(data)
  end

  def validate_string_keys(data)
    %w[purpose_statement meeting_structure member_commitments].each do |key|
      unless data[key].is_a?(String) && data[key].present?
        raise ParseError, "Missing or blank required key: #{key}"
      end
    end
  end

  def validate_agreements(data)
    agreements = data["agreements"]
    unless agreements.is_a?(Array) && agreements.size.between?(4, 5)
      raise ParseError, "agreements must be an Array with 4 or 5 entries (got #{agreements.inspect})"
    end
  end

  def validate_sessions(data)
    sessions = data["sessions"]
    unless sessions.is_a?(Array) && sessions.size == 4
      raise ParseError, "sessions must be an Array with exactly 4 entries (got #{sessions&.size})"
    end

    expected_numbers = [1, 2, 3, 4]
    actual_numbers   = sessions.map { |s| s["session_number"] }
    unless actual_numbers == expected_numbers
      raise ParseError, "sessions must have session_number values [1, 2, 3, 4] in order (got #{actual_numbers.inspect})"
    end
  end

  def validate_boundary_reminders(data)
    reminders = data["boundary_reminders"]
    unless reminders.is_a?(Array) && reminders.size == 2
      raise ParseError, "boundary_reminders must be an Array with exactly 2 entries (got #{reminders.inspect})"
    end
  end
end
```

### 4.2 — `spec/fixtures/files/sample_grief_circle_response.json`

Create a hand-written valid JSON fixture representing a fully generated charter for the Tuesday Grief Circle. This file is shared between seeds (Phase 6) and request specs (Phase 5). Keep it valid against the parser schema at all times.

```json
{
  "purpose_statement": "This group provides structured peer support for adults navigating the first year of grief after losing a spouse or parent. Grounded in the S.A.F.E. framework, we create space for shared experience, mutual accountability, and steady forward movement. The group is not therapy; it is companionship with structure.",
  "meeting_structure": "Each 90-minute meeting opens with a brief check-in round where each member shares one word or sentence about how they arrived. The facilitator introduces a discussion topic drawn from the S.A.F.E. Formation arc. Members share in turn, listening without cross-talk. A short paired activity follows. The meeting closes with a shared phrase or moment of silence chosen by the group in Session 1.",
  "member_commitments": "Members agree to attend at least three of every four meetings. What is shared in the room stays in the room. Members listen to understand, not to fix. Members refrain from giving unsolicited advice or comparing grief timelines.",
  "agreements": [
    "Confidentiality: what is shared here stays here.",
    "No advice unless asked for.",
    "One voice at a time; no cross-talk.",
    "It is okay to pass on any prompt.",
    "Grief has no timeline; we do not compare losses."
  ],
  "sessions": [
    {
      "session_number": 1,
      "title": "Trust Building",
      "check_in_format": "Each member shares their name and one word describing how they arrived today.",
      "discussion_topic": "What brought you to this group, and what do you hope to find here? What does support look like for you right now?",
      "activity": "Pairs take three minutes each to share one memory of the person they lost, without interruption or response. Partners simply witness.",
      "closing_ritual": "The group chooses a closing phrase together — a simple sentence spoken aloud by everyone — that will close every future session."
    },
    {
      "session_number": 2,
      "title": "Expectation Setting",
      "check_in_format": "Each member shares one thing that happened this week, small or large.",
      "discussion_topic": "What has surprised you most about grief? What do you wish people around you understood about where you are right now?",
      "activity": "Each member writes one expectation they are releasing — something they thought grief would look like — on a card. Cards are shared aloud and collected by the facilitator.",
      "closing_ritual": "The group's chosen closing phrase from Session 1."
    },
    {
      "session_number": 3,
      "title": "Deepening",
      "check_in_format": "Each member shares one moment from the past two weeks where they felt the absence most.",
      "discussion_topic": "What practices, routines, or people have helped you carry the weight this week? What gets harder before it gets easier?",
      "activity": "Small group reflection: in triads, members take turns answering: what is one thing you are still learning about how to grieve?",
      "closing_ritual": "The group's chosen closing phrase from Session 1."
    },
    {
      "session_number": 4,
      "title": "Pattern Review and Forward Planning",
      "check_in_format": "Each member shares one thing that is different for them now compared to Session 1.",
      "discussion_topic": "Looking at the past four sessions, what has shifted? What do you want to carry forward from this group into the next season of your life?",
      "activity": "Each member writes a one-sentence intention for the next 30 days and shares it with the group. The facilitator reads them back at the close.",
      "closing_ritual": "The group's chosen closing phrase, followed by a moment of silence."
    }
  ],
  "boundary_reminders": [
    "I want to pause here. What you are describing sounds like it may need more than our group can hold — have you considered speaking with a grief counselor or therapist one on one?",
    "This group is peer support, not crisis support. If you are in acute distress right now, please reach out to the 988 Suicide and Crisis Lifeline or a trusted clinician before our next meeting."
  ]
}
```

---

## RSpec — Phase 4

Run after completing all tasks above:

```bash
bundle exec rspec spec/services/charter_parser_spec.rb
```

### `spec/services/charter_parser_spec.rb`

```ruby
RSpec.describe CharterParser do
  let(:valid_json) { File.read(Rails.root.join("spec/fixtures/files/sample_grief_circle_response.json")) }

  describe "#parse!" do
    context "with a well-formed response" do
      it "returns a hash with all required keys"
      it "returns the agreements array"
      it "returns exactly 4 sessions"
      it "returns boundary_reminders array with 2 entries"
    end

    context "with a Markdown code fence wrapper" do
      it "strips ```json fences and parses correctly"
      it "strips plain ``` fences and parses correctly"
    end

    context "with invalid JSON" do
      it "raises ParseError with a descriptive message"
      it "ParseError#refusal? returns false"
    end

    context "with a refusal response" do
      let(:refusal_json) { '{"refusal": "This brief describes a clinical context."}' }

      it "raises ParseError"
      it "ParseError#refusal? returns true"
      it "ParseError message contains the refusal text"
    end

    context "schema validation" do
      it "raises ParseError if purpose_statement is missing"
      it "raises ParseError if meeting_structure is missing"
      it "raises ParseError if member_commitments is missing"

      it "raises ParseError if agreements has fewer than 4 entries"
      it "raises ParseError if agreements has more than 5 entries"

      it "raises ParseError if sessions has 3 entries"
      it "raises ParseError if sessions has 5 entries"
      it "raises ParseError if session_numbers are out of order (e.g. [1,2,4,3])"
      it "raises ParseError if session_numbers don't start at 1 (e.g. [2,3,4,5])"

      it "raises ParseError if boundary_reminders has 1 entry"
      it "raises ParseError if boundary_reminders has 3 entries"

      it "does NOT raise if target_demographics is absent (it is input, not output)"
    end
  end
end
```

---

## Manual Checks — Phase 4

- [ ] `bundle exec rspec spec/services/charter_parser_spec.rb` — all pass, zero failures
- [ ] Rails console: `CharterParser.new(File.read("spec/fixtures/files/sample_grief_circle_response.json")).parse!` returns a hash without error
- [ ] Rails console: `CharterParser.new('{"refusal": "This is a clinical context."}').parse!` raises `CharterParser::ParseError` with `refusal? == true`
- [ ] Rails console: `CharterParser.new('not json at all').parse!` raises `CharterParser::ParseError` with `refusal? == false`
- [ ] Rails console: `CharterParser.new("```json\n#{File.read('spec/fixtures/files/sample_grief_circle_response.json')}\n```").parse!` succeeds (fence stripping works)
