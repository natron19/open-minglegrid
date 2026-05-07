class CreateGroupCharters < ActiveRecord::Migration[8.1]
  def change
    create_table :group_charters, id: :uuid do |t|
      t.references :support_group, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.text :purpose_statement
      t.text :meeting_structure
      t.text :member_commitments
      t.text :agreements
      t.text :boundary_reminders
      t.text :gemini_raw
      t.datetime :generated_at
      t.timestamps null: false
    end
  end
end
