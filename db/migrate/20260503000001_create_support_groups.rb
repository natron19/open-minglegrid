class CreateSupportGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :support_groups, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string  :name,                   null: false
      t.text    :purpose,                null: false
      t.text    :target_demographics
      t.string  :meeting_cadence,        null: false
      t.integer :session_length_minutes, null: false
      t.string  :organization_type,      null: false
      t.timestamps null: false
    end

    add_index :support_groups, :updated_at
  end
end
