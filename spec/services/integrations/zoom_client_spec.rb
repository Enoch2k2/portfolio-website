require "rails_helper"

module Integrations
  RSpec.describe ZoomClient do
    def build_meeting(topic: "Website Consultation")
      Meeting.new(
        name: "Jane Doe",
        email: "jane@example.com",
        timezone: "UTC",
        start_at: Time.utc(2026, 2, 20, 15, 0, 0),
        end_at: Time.utc(2026, 2, 20, 15, 30, 0),
        topic: topic,
        notes: "Interested in product strategy",
        status: "tentative",
        idempotency_key: SecureRandom.uuid
      )
    end

    it "sends name and topic in zoom meeting title" do
      client = described_class.new(access_token: "token")
      meeting = build_meeting

      request_double = instance_double(Net::HTTP::Post)
      response_double = double(body: { id: 123, join_url: "https://zoom.us/j/123" }.to_json)
      allow(response_double).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      expect(Net::HTTP::Post).to receive(:new).with(described_class::CREATE_MEETING_URI).and_return(request_double)
      expect(request_double).to receive(:[]=).with("Authorization", "Bearer token")
      expect(request_double).to receive(:[]=).with("Content-Type", "application/json")
      expect(request_double).to receive(:body=).with(
        include("\"topic\":\"Jane Doe - Website Consultation\"")
      )
      expect(Net::HTTP).to receive(:start)
        .with(described_class::CREATE_MEETING_URI.host, described_class::CREATE_MEETING_URI.port, use_ssl: true)
        .and_yield(instance_double(Net::HTTP, request: response_double))

      client.create_meeting!(meeting: meeting)
    end

    it "falls back to default topic in zoom meeting title when topic is blank" do
      client = described_class.new(access_token: "token")
      meeting = build_meeting(topic: nil)

      request_double = instance_double(Net::HTTP::Post)
      response_double = double(body: { id: 123, join_url: "https://zoom.us/j/123" }.to_json)
      allow(response_double).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      expect(Net::HTTP::Post).to receive(:new).with(described_class::CREATE_MEETING_URI).and_return(request_double)
      expect(request_double).to receive(:[]=).with("Authorization", "Bearer token")
      expect(request_double).to receive(:[]=).with("Content-Type", "application/json")
      expect(request_double).to receive(:body=).with(
        include("\"topic\":\"Jane Doe - Client Discovery Call\"")
      )
      expect(Net::HTTP).to receive(:start)
        .with(described_class::CREATE_MEETING_URI.host, described_class::CREATE_MEETING_URI.port, use_ssl: true)
        .and_yield(instance_double(Net::HTTP, request: response_double))

      client.create_meeting!(meeting: meeting)
    end
  end
end
