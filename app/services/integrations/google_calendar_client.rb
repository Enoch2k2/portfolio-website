require "net/http"
require "time"

module Integrations
  class GoogleCalendarClient
    EVENTS_URI = URI("https://www.googleapis.com/calendar/v3/calendars/primary/events")
    FREEBUSY_URI = URI("https://www.googleapis.com/calendar/v3/freeBusy")

    def initialize(access_token:)
      @access_token = access_token
    end

    def create_event!(meeting:, zoom_join_url: nil)
      description_lines = []
      description_lines << "Zoom: #{zoom_join_url}" if zoom_join_url.present?
      description_lines << meeting.notes.to_s if meeting.notes.present?

      body = {
        summary: meeting.topic.presence || "Client Discovery Call",
        description: description_lines.join("\n\n"),
        attendees: [{ email: meeting.email }],
        start: { dateTime: meeting.start_at.iso8601 },
        end: { dateTime: meeting.end_at.iso8601 }
      }
      perform_post!(EVENTS_URI, body, "Google Calendar event creation failed")
    end

    def freebusy(time_min:, time_max:)
      payload = {
        timeMin: time_min.utc.iso8601,
        timeMax: time_max.utc.iso8601,
        items: [{ id: "primary" }]
      }
      body = perform_post!(FREEBUSY_URI, payload, "Google Calendar freebusy query failed")
      busy = body.dig("calendars", "primary", "busy") || []
      busy.filter_map do |window|
        start_at = window["start"]
        end_at = window["end"]
        next if start_at.blank? || end_at.blank?

        {
          start_at: Time.iso8601(start_at).utc,
          end_at: Time.iso8601(end_at).utc
        }
      rescue ArgumentError
        nil
      end
    end

    private

    def perform_post!(uri, payload, fallback_error)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
      body = JSON.parse(response.body)
      raise(body["error"]&.dig("message") || body["error_description"] || fallback_error) unless response.is_a?(Net::HTTPSuccess)

      body
    end
  end
end
