require "rails_helper"

RSpec.describe SupportGroup, type: :model do
  describe "factory" do
    it "is valid with valid attributes" do
      expect(build(:support_group)).to be_valid
    end
  end

  describe "associations" do
    it "is invalid without a user" do
      expect(build(:support_group, user: nil)).not_to be_valid
    end

    it "has one group_charter" do
      group = create(:support_group)
      charter = create(:group_charter, support_group: group)
      expect(group.group_charter).to eq(charter)
    end
  end

  describe "name" do
    it "requires name" do
      expect(build(:support_group, name: nil)).not_to be_valid
    end

    it "requires name to be at least 2 characters" do
      expect(build(:support_group, name: "A")).not_to be_valid
    end

    it "rejects name over 80 characters" do
      expect(build(:support_group, name: "A" * 81)).not_to be_valid
    end

    it "accepts name at the 2-character minimum" do
      expect(build(:support_group, name: "AA")).to be_valid
    end

    it "accepts name at the 80-character maximum" do
      expect(build(:support_group, name: "A" * 80)).to be_valid
    end
  end

  describe "purpose" do
    it "requires purpose" do
      expect(build(:support_group, purpose: nil)).not_to be_valid
    end

    it "requires purpose to be at least 20 characters" do
      expect(build(:support_group, purpose: "Too short.")).not_to be_valid
    end

    it "rejects purpose over 1000 characters" do
      expect(build(:support_group, purpose: "A" * 1001)).not_to be_valid
    end

    it "accepts purpose at the 20-character minimum" do
      expect(build(:support_group, purpose: "A" * 20)).to be_valid
    end
  end

  describe "target_demographics" do
    it "is optional" do
      expect(build(:support_group, target_demographics: nil)).to be_valid
    end

    it "rejects target_demographics over 500 characters" do
      expect(build(:support_group, target_demographics: "A" * 501)).not_to be_valid
    end
  end

  describe "meeting_cadence" do
    it "requires meeting_cadence" do
      expect(build(:support_group, meeting_cadence: nil)).not_to be_valid
    end

    it "accepts all values in MEETING_CADENCES" do
      SupportGroup::MEETING_CADENCES.each do |cadence|
        expect(build(:support_group, meeting_cadence: cadence)).to be_valid
      end
    end

    it "rejects values not in MEETING_CADENCES" do
      expect(build(:support_group, meeting_cadence: "daily")).not_to be_valid
    end
  end

  describe "organization_type" do
    it "requires organization_type" do
      expect(build(:support_group, organization_type: nil)).not_to be_valid
    end

    it "accepts all values in ORGANIZATION_TYPES" do
      SupportGroup::ORGANIZATION_TYPES.each do |type|
        expect(build(:support_group, organization_type: type)).to be_valid
      end
    end

    it "rejects values not in ORGANIZATION_TYPES" do
      expect(build(:support_group, organization_type: "corporation")).not_to be_valid
    end
  end

  describe "session_length_minutes" do
    it "requires session_length_minutes" do
      expect(build(:support_group, session_length_minutes: nil)).not_to be_valid
    end

    it "accepts 30 (minimum)" do
      expect(build(:support_group, session_length_minutes: 30)).to be_valid
    end

    it "accepts 180 (maximum)" do
      expect(build(:support_group, session_length_minutes: 180)).to be_valid
    end

    it "rejects 29" do
      expect(build(:support_group, session_length_minutes: 29)).not_to be_valid
    end

    it "rejects 181" do
      expect(build(:support_group, session_length_minutes: 181)).not_to be_valid
    end
  end

  describe "cascade destroy" do
    it "destroys the charter and all sessions when the group is destroyed" do
      group = create(:support_group, :with_charter)

      expect { group.destroy }
        .to change(GroupCharter, :count).by(-1)
        .and change(LaunchSession, :count).by(-4)
    end
  end
end
