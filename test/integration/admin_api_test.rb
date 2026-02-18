require "test_helper"

class AdminApiTest < ActionDispatch::IntegrationTest
  setup do
    @token = "test-admin-token"
    ENV["ADMIN_API_TOKEN"] = @token
    ENV["ADMIN_LOGIN_EMAIL"] = "admin@example.com"
    ENV["ADMIN_LOGIN_PASSWORD"] = "secret123"
  end

  test "admin session login returns token" do
    post "/api/v1/admin/session", params: { email: "admin@example.com", password: "secret123" }
    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal @token, payload["token"]
  end

  test "admin can create blog post with auth token" do
    post "/api/v1/admin/blog_posts",
         params: {
           blog_post: {
             title: "Admin Post",
             slug: "admin-post",
             summary: "summary",
             markdown_body: "# Body",
             status: "draft",
             tag_names: ["rails", "react"]
           }
         },
         headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal "Admin Post", payload["title"]
    assert_equal 2, payload["tag_names"].size
  end

  test "admin site content includes resume field" do
    get "/api/v1/admin/site_content", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success

    payload = JSON.parse(response.body)
    assert payload.key?("hero_photo_url")
    assert payload.key?("resume_url")
  end

  test "admin resume upload requires a file" do
    post "/api/v1/admin/site_content/resume", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :unprocessable_entity

    payload = JSON.parse(response.body)
    assert_equal "file is required", payload["error"]
  end
end
