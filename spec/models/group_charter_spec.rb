require "rails_helper"

RSpec.describe GroupCharter, type: :model do
  describe "factory" do
    it "is valid with valid attributes" do
      expect(build(:group_charter)).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a support_group" do
      charter = create(:group_charter)
      expect(charter.support_group).to be_a(SupportGroup)
    end

    it "has many launch_sessions" do
      charter = create(:group_charter)
      create(:launch_session, group_charter: charter, session_number: 1)
      create(:launch_session, group_charter: charter, session_number: 2)
      expect(charter.launch_sessions.count).to eq(2)
    end
  end

  describe "validations" do
    it "requires gemini_raw" do
      expect(build(:group_charter, gemini_raw: nil)).not_to be_valid
    end

    it "requires gemini_raw to not be blank" do
      expect(build(:group_charter, gemini_raw: "")).not_to be_valid
    end

    it "rejects a second charter for the same support group" do
      existing = create(:group_charter)
      duplicate = build(:group_charter, support_group: existing.support_group)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:support_group_id]).to be_present
    end
  end

  describe "#agreements_list" do
    it "parses a valid JSON array" do
      charter = build(:group_charter, agreements: '["First.", "Second."]')
      expect(charter.agreements_list).to eq(["First.", "Second."])
    end

    it "returns [] when agreements is nil" do
      charter = build(:group_charter, agreements: nil)
      expect(charter.agreements_list).to eq([])
    end

    it "returns [] when agreements is malformed JSON" do
      charter = build(:group_charter, agreements: "{ not valid")
      expect(charter.agreements_list).to eq([])
    end
  end

  describe "#boundary_reminders_list" do
    it "parses a valid JSON array" do
      charter = build(:group_charter, boundary_reminders: '["Reminder one.", "Reminder two."]')
      expect(charter.boundary_reminders_list).to eq(["Reminder one.", "Reminder two."])
    end

    it "returns [] when boundary_reminders is nil" do
      charter = build(:group_charter, boundary_reminders: nil)
      expect(charter.boundary_reminders_list).to eq([])
    end

    it "returns [] when boundary_reminders is malformed JSON" do
      charter = build(:group_charter, boundary_reminders: "{ broken")
      expect(charter.boundary_reminders_list).to eq([])
    end
  end

  describe "cascade destroy" do
    it "destroys associated launch sessions when charter is destroyed" do
      charter = create(:group_charter)
      create(:launch_session, group_charter: charter, session_number: 1)
      create(:launch_session, group_charter: charter, session_number: 2)

      expect { charter.destroy }.to change(LaunchSession, :count).by(-2)
    end
  end
end
