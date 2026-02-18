require "rails_helper"

module Integrations
  RSpec.describe GoogleCalendarClient do
    def build_meeting(topic: "Website Consultation")
      Meeting.new(
        name: "Jane Doe",
        email: "jane@example.com",
        timezone: "UTC",
        start_at: Time.utc(2026, 2, 20, 15, 0, 0),
        end_at: Time.utc(2026, 2, 20, 15, 30, 0),
        topic: topic,
        notes: "Interested in a redesign",
        status: "tentative",
        idempotency_key: SecureRandom.uuid
      )
    end

    it "uses name and topic in google event summary" do
      client = described_class.new(access_token: "token")
      meeting = build_meeting

      expect(client).to receive(:perform_post!).with(
        described_class::EVENTS_URI,
        hash_including(summary: "Jane Doe - Website Consultation"),
        "Google Calendar event creation failed"
      ).and_return({ "id" => "evt_123" })

      client.create_event!(meeting: meeting, zoom_join_url: "https://zoom.us/j/123")
    end

    it "falls back to default topic in summary when topic is blank" do
      client = described_class.new(access_token: "token")
      meeting = build_meeting(topic: nil)

      expect(client).to receive(:perform_post!).with(
        described_class::EVENTS_URI,
        hash_including(summary: "Jane Doe - Client Discovery Call"),
        "Google Calendar event creation failed"
      ).and_return({ "id" => "evt_123" })

      client.create_event!(meeting: meeting)
    end
  end
end
