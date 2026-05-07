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
