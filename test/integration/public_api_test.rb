require "test_helper"

class PublicApiTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
  end

  test "returns published blog posts" do
    post = BlogPost.create!(
      title: "Published Post",
      slug: "published-post",
      summary: "Summary",
      markdown_body: "# Hello",
      status: "published",
      published_at: Time.current
    )

    get "/api/v1/public/blog_posts"
    assert_response :success

    payload = JSON.parse(response.body)
    assert(payload.any? { |item| item["slug"] == post.slug })
  end

  test "creates meeting request" do
    start_time = Time.current.utc.change(hour: 10, min: 0, sec: 0) + 1.day
    start_time += 1.day until (1..5).include?(start_time.wday)
    end_time = start_time + 30.minutes

    assert_enqueued_jobs 1, only: ProvisionMeetingJob do
      post "/api/v1/public/meetings", params: {
        meeting: {
          name: "Test User",
          email: "test@example.com",
          timezone: "UTC",
          start_at: start_time.iso8601,
          end_at: end_time.iso8601,
          topic: "Discovery",
          notes: "Interested in collaboration"
        }
      }
    end

    assert_response :accepted
    payload = JSON.parse(response.body)
    assert_equal "tentative", payload["status"]
  end

  test "returns availability grouped by day" do
    get "/api/v1/public/availability", params: { timezone: "UTC", days: 5 }
    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal "UTC", payload["timezone"]
    assert payload["days"].is_a?(Array)
    assert payload["slots"].is_a?(Array)
  end

  test "returns public site content with resume field" do
    get "/api/v1/public/site_content"
    assert_response :success

    payload = JSON.parse(response.body)
    assert payload.key?("hero_photo_url")
    assert payload.key?("resume_url")
  end
end
