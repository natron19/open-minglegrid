class LaunchSession < ApplicationRecord
  belongs_to :group_charter
  has_one :support_group, through: :group_charter

  validates :session_number,   presence: true, inclusion: { in: 1..4 }
  validates :session_number,   uniqueness: { scope: :group_charter_id }
  validates :title,            presence: true
  validates :check_in_format,  presence: true
  validates :discussion_topic, presence: true
  validates :activity,         presence: true
  validates :closing_ritual,   presence: true

  def completed?
    completed_at.present?
  end
end
