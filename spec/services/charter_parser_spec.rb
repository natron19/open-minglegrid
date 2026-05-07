require "rails_helper"

RSpec.describe CharterParser do
  let(:valid_json) { File.read(Rails.root.join("spec/fixtures/files/sample_grief_circle_response.json")) }

  def valid_data
    JSON.parse(valid_json)
  end

  def build_json(overrides = {})
    valid_data.merge(overrides).to_json
  end

  describe "#parse!" do
    context "with a well-formed response" do
      subject(:result) { described_class.new(valid_json).parse! }

      it "returns a hash with all required keys" do
        expect(result).to include("purpose_statement", "meeting_structure", "member_commitments",
                                  "agreements", "sessions", "boundary_reminders")
      end

      it "returns the agreements array" do
        expect(result["agreements"]).to be_an(Array)
        expect(result["agreements"].size).to eq(5)
      end

      it "returns exactly 4 sessions" do
        expect(result["sessions"].size).to eq(4)
      end

      it "returns boundary_reminders array with 2 entries" do
        expect(result["boundary_reminders"].size).to eq(2)
      end
    end

    context "with a Markdown code fence wrapper" do
      it "strips ```json fences and parses correctly" do
        wrapped = "```json\n#{valid_json}\n```"
        expect { described_class.new(wrapped).parse! }.not_to raise_error
      end

      it "strips plain ``` fences and parses correctly" do
        wrapped = "```\n#{valid_json}\n```"
        expect { described_class.new(wrapped).parse! }.not_to raise_error
      end
    end

    context "with invalid JSON" do
      let(:bad_input) { "not json at all" }

      it "raises ParseError with a descriptive message" do
        expect { described_class.new(bad_input).parse! }
          .to raise_error(CharterParser::ParseError, /Invalid JSON/)
      end

      it "ParseError#refusal? returns false" do
        begin
          described_class.new(bad_input).parse!
        rescue CharterParser::ParseError => e
          expect(e.refusal?).to be(false)
        end
      end
    end

    context "with a refusal response" do
      let(:refusal_json) { '{"refusal": "This brief describes a clinical context."}' }

      it "raises ParseError" do
        expect { described_class.new(refusal_json).parse! }
          .to raise_error(CharterParser::ParseError)
      end

      it "ParseError#refusal? returns true" do
        begin
          described_class.new(refusal_json).parse!
        rescue CharterParser::ParseError => e
          expect(e.refusal?).to be(true)
        end
      end

      it "ParseError message contains the refusal text" do
        begin
          described_class.new(refusal_json).parse!
        rescue CharterParser::ParseError => e
          expect(e.message).to include("This brief describes a clinical context.")
        end
      end
    end

    context "schema validation" do
      it "raises ParseError if purpose_statement is missing" do
        json = build_json("purpose_statement" => nil)
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /purpose_statement/)
      end

      it "raises ParseError if meeting_structure is missing" do
        json = build_json("meeting_structure" => "")
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /meeting_structure/)
      end

      it "raises ParseError if member_commitments is missing" do
        json = build_json("member_commitments" => nil)
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /member_commitments/)
      end

      it "raises ParseError if agreements has fewer than 4 entries" do
        json = build_json("agreements" => ["one", "two", "three"])
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /agreements/)
      end

      it "raises ParseError if agreements has more than 5 entries" do
        json = build_json("agreements" => ["one", "two", "three", "four", "five", "six"])
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /agreements/)
      end

      it "raises ParseError if sessions has 3 entries" do
        sessions = valid_data["sessions"].first(3)
        json = build_json("sessions" => sessions)
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /sessions/)
      end

      it "raises ParseError if sessions has 5 entries" do
        extra = valid_data["sessions"].first.merge("session_number" => 5)
        sessions = valid_data["sessions"] + [extra]
        json = build_json("sessions" => sessions)
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /sessions/)
      end

      it "raises ParseError if session_numbers are out of order (e.g. [1,2,4,3])" do
        sessions = valid_data["sessions"].dup
        sessions[2] = sessions[2].merge("session_number" => 4)
        sessions[3] = sessions[3].merge("session_number" => 3)
        json = build_json("sessions" => sessions)
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /session_number/)
      end

      it "raises ParseError if session_numbers don't start at 1 (e.g. [2,3,4,5])" do
        sessions = valid_data["sessions"].map.with_index { |s, i| s.merge("session_number" => i + 2) }
        json = build_json("sessions" => sessions)
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /session_number/)
      end

      it "raises ParseError if boundary_reminders has 1 entry" do
        json = build_json("boundary_reminders" => ["just one"])
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /boundary_reminders/)
      end

      it "raises ParseError if boundary_reminders has 3 entries" do
        json = build_json("boundary_reminders" => ["one", "two", "three"])
        expect { described_class.new(json).parse! }.to raise_error(CharterParser::ParseError, /boundary_reminders/)
      end

      it "does NOT raise if target_demographics is absent (it is input, not output)" do
        expect { described_class.new(valid_json).parse! }.not_to raise_error
      end
    end
  end
end
