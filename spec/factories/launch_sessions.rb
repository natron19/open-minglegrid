FactoryBot.define do
  factory :launch_session do
    association :group_charter
    session_number   { 1 }
    title            { "Trust Building" }
    check_in_format  { "Each member shares one word describing how they arrived today." }
    discussion_topic { "What brought you to this group, and what do you hope to find here?" }
    activity         { "Pair sharing: partners take three minutes each to share without interruption." }
    closing_ritual   { "A moment of silence followed by one word each for how you are leaving." }

    trait :sequential do
      sequence(:session_number) { |n| n }
      title { "Session #{session_number}" }
    end
  end
end
