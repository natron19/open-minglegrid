FactoryBot.define do
  factory :group_charter do
    association :support_group
    purpose_statement  { "This group provides structured peer support for adults navigating early grief." }
    meeting_structure  { "Each meeting opens with a brief check-in, moves into a discussion topic, and closes with a shared reflection." }
    member_commitments { "Members agree to attend regularly, hold each other's stories in confidence, and refrain from giving unsolicited advice." }
    agreements         { '["Confidentiality: what is shared here stays here.", "No advice unless asked.", "One voice at a time.", "It is okay to pass."]' }
    boundary_reminders { '["If what you are describing sounds like it needs more than peer support can hold, I can help you find a counselor.", "This is a peer group, not therapy. If you are in crisis, please call 988."]' }
    gemini_raw         { agreements }
    generated_at       { Time.current }

    trait :with_sessions do
      after(:create) do |charter|
        create(:launch_session, group_charter: charter, session_number: 1)
        create(:launch_session, group_charter: charter, session_number: 2)
        create(:launch_session, group_charter: charter, session_number: 3)
        create(:launch_session, group_charter: charter, session_number: 4)
      end
    end
  end
end
