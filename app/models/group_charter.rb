class GroupCharter < ApplicationRecord
  belongs_to :support_group
  has_one :user, through: :support_group
  has_many :launch_sessions, dependent: :destroy

  validates :support_group_id, uniqueness: true
  validates :gemini_raw, presence: true

  def agreements_list
    JSON.parse(agreements || "[]")
  rescue JSON::ParserError
    []
  end

  def boundary_reminders_list
    JSON.parse(boundary_reminders || "[]")
  rescue JSON::ParserError
    []
  end
end
