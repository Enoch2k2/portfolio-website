class CreateAvailabilityRules < ActiveRecord::Migration[8.1]
  def change
    create_table :availability_rules do |t|
      t.integer :weekday, null: false
      t.string :timezone, null: false, default: "UTC"
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :availability_rules, :weekday
    add_index :availability_rules, :active
  end
end
