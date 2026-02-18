class CreateProfileSections < ActiveRecord::Migration[8.1]
  def change
    create_table :profile_sections do |t|
      t.string :key, null: false
      t.string :title, null: false
      t.text :markdown_body, null: false, default: ""
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true

      t.timestamps
    end

    add_index :profile_sections, :key, unique: true
    add_index :profile_sections, :position
  end
end
