class CreateLaunchSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :launch_sessions, id: :uuid do |t|
      t.references :group_charter, null: false, foreign_key: true, type: :uuid
      t.integer :session_number,   null: false
      t.string  :title,            null: false
      t.text    :check_in_format,  null: false
      t.text    :discussion_topic, null: false
      t.text    :activity,         null: false
      t.text    :closing_ritual,   null: false
      t.timestamps null: false
    end

    add_index :launch_sessions, [:group_charter_id, :session_number], unique: true
  end
end
