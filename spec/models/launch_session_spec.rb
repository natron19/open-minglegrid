require "rails_helper"

RSpec.describe LaunchSession, type: :model do
  describe "factory" do
    it "is valid with valid attributes" do
      expect(build(:launch_session)).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a group_charter" do
      session = create(:launch_session)
      expect(session.group_charter).to be_a(GroupCharter)
    end
  end

  describe "presence validations" do
    it "requires title" do
      expect(build(:launch_session, title: nil)).not_to be_valid
    end

    it "requires check_in_format" do
      expect(build(:launch_session, check_in_format: nil)).not_to be_valid
    end

    it "requires discussion_topic" do
      expect(build(:launch_session, discussion_topic: nil)).not_to be_valid
    end

    it "requires activity" do
      expect(build(:launch_session, activity: nil)).not_to be_valid
    end

    it "requires closing_ritual" do
      expect(build(:launch_session, closing_ritual: nil)).not_to be_valid
    end
  end

  describe "session_number" do
    it "requires session_number" do
      expect(build(:launch_session, session_number: nil)).not_to be_valid
    end

    it "accepts 1 through 4" do
      (1..4).each do |n|
        expect(build(:launch_session, session_number: n)).to be_valid
      end
    end

    it "rejects 0" do
      expect(build(:launch_session, session_number: 0)).not_to be_valid
    end

    it "rejects 5" do
      expect(build(:launch_session, session_number: 5)).not_to be_valid
    end

    it "rejects a duplicate session_number on the same charter" do
      charter = create(:group_charter)
      create(:launch_session, group_charter: charter, session_number: 1)
      duplicate = build(:launch_session, group_charter: charter, session_number: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:session_number]).to be_present
    end

    it "allows the same session_number on a different charter" do
      create(:launch_session, session_number: 1)
      other = build(:launch_session, session_number: 1)
      expect(other).to be_valid
    end
  end
end
