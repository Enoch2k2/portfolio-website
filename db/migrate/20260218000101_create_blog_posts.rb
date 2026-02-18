class CreateBlogPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary
      t.text :markdown_body, null: false, default: ""
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.datetime :scheduled_for
      t.string :seo_title
      t.string :seo_description
      t.string :og_image_url

      t.timestamps
    end

    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :status
    add_index :blog_posts, :published_at
  end
end
