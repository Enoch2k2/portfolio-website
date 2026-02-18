class CreateBlogTags < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_tags do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    create_table :blog_post_tags do |t|
      t.references :blog_post, null: false, foreign_key: true
      t.references :blog_tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :blog_tags, :slug, unique: true
    add_index :blog_post_tags, [:blog_post_id, :blog_tag_id], unique: true
  end
end
