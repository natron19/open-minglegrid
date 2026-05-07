class AddSchedulingToLaunchSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :launch_sessions, :scheduled_at, :datetime
    add_column :launch_sessions, :completed_at, :datetime
  end
end
