require "test_helper"

class MeetingMailerTest < ActionMailer::TestCase
  test "confirmation email includes date time and zoom link" do
    meeting = Meeting.create!(
      name: "Test User",
      email: "test@example.com",
      timezone: "America/New_York",
      start_at: Time.utc(2026, 2, 20, 15, 0, 0),
      end_at: Time.utc(2026, 2, 20, 15, 30, 0),
      topic: "Discovery Call",
      notes: "Initial meeting",
      idempotency_key: SecureRandom.uuid,
      status: "scheduled",
      zoom_join_url: "https://zoom.us/j/1234567890"
    )

    email = MeetingMailer.confirmation_email(meeting)

    assert_equal ["test@example.com"], email.to
    assert_equal "Meeting confirmed: Discovery Call", email.subject
    assert_includes email.body.to_s, "Date:"
    assert_includes email.body.to_s, "Time:"
    assert_includes email.body.to_s, "Zoom: https://zoom.us/j/1234567890"
  end
end
