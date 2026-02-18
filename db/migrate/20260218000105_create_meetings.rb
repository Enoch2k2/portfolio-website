class CreateMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :timezone, null: false, default: "UTC"
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.string :status, null: false, default: "tentative"
      t.string :topic
      t.string :notes
      t.string :zoom_join_url
      t.string :zoom_meeting_id
      t.string :google_event_id
      t.string :idempotency_key, null: false
      t.datetime :provisioned_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :meetings, :start_at
    add_index :meetings, :status
    add_index :meetings, :idempotency_key, unique: true
  end
end
