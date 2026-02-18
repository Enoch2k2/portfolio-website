# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_18_063010) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "availability_rules", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.time "end_time", null: false
    t.time "start_time", null: false
    t.string "timezone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.integer "weekday", null: false
    t.index ["active"], name: "index_availability_rules_on_active"
    t.index ["weekday"], name: "index_availability_rules_on_weekday"
  end

  create_table "blog_post_tags", force: :cascade do |t|
    t.bigint "blog_post_id", null: false
    t.bigint "blog_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_post_id", "blog_tag_id"], name: "index_blog_post_tags_on_blog_post_id_and_blog_tag_id", unique: true
    t.index ["blog_post_id"], name: "index_blog_post_tags_on_blog_post_id"
    t.index ["blog_tag_id"], name: "index_blog_post_tags_on_blog_tag_id"
  end

  create_table "blog_posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "markdown_body", default: "", null: false
    t.string "og_image_url"
    t.datetime "published_at"
    t.datetime "scheduled_for"
    t.string "seo_description"
    t.string "seo_title"
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_blog_posts_on_published_at"
    t.index ["slug"], name: "index_blog_posts_on_slug", unique: true
    t.index ["status"], name: "index_blog_posts_on_status"
  end

  create_table "blog_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_blog_tags_on_slug", unique: true
  end

  create_table "meetings", force: :cascade do |t|
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "end_at", null: false
    t.string "google_event_id"
    t.string "idempotency_key", null: false
    t.string "name", null: false
    t.string "notes"
    t.datetime "provisioned_at"
    t.datetime "start_at", null: false
    t.string "status", default: "tentative", null: false
    t.string "timezone", default: "UTC", null: false
    t.string "topic"
    t.datetime "updated_at", null: false
    t.string "zoom_join_url"
    t.string "zoom_meeting_id"
    t.index ["idempotency_key"], name: "index_meetings_on_idempotency_key", unique: true
    t.index ["start_at"], name: "index_meetings_on_start_at"
    t.index ["status"], name: "index_meetings_on_status"
  end

  create_table "oauth_integrations", force: :cascade do |t|
    t.text "access_token"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "external_account_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "provider", null: false
    t.text "refresh_token"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_oauth_integrations_on_active"
    t.index ["provider"], name: "index_oauth_integrations_on_provider", unique: true
  end

  create_table "profile_sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.text "markdown_body", default: "", null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_profile_sections_on_key", unique: true
    t.index ["position"], name: "index_profile_sections_on_position"
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "role", default: "admin", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blog_post_tags", "blog_posts"
  add_foreign_key "blog_post_tags", "blog_tags"
end
