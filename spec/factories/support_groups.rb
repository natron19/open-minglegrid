FactoryBot.define do
  factory :support_group do
    association :user
    name                   { "Tuesday Grief Circle" }
    purpose                { "Peer support for adults grieving a spouse or parent in their first year of loss." }
    target_demographics    { "Adults over 40 in a small congregation." }
    meeting_cadence        { "weekly" }
    session_length_minutes { 90 }
    organization_type      { "faith_community" }

    trait :with_charter do
      after(:create) do |group|
        charter = create(:group_charter, support_group: group)
        create(:launch_session, group_charter: charter, session_number: 1)
        create(:launch_session, group_charter: charter, session_number: 2)
        create(:launch_session, group_charter: charter, session_number: 3)
        create(:launch_session, group_charter: charter, session_number: 4)
      end
    end
  end
end
