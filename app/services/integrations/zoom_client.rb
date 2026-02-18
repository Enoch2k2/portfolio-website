require "net/http"

module Integrations
  class ZoomClient
    CREATE_MEETING_URI = URI("https://api.zoom.us/v2/users/me/meetings")

    def initialize(access_token:)
      @access_token = access_token
    end

    def create_meeting!(meeting:)
      topic = meeting.topic.presence || "Client Discovery Call"
      meeting_title = "#{meeting.name} - #{topic}"
      request = Net::HTTP::Post.new(CREATE_MEETING_URI)
      request["Authorization"] = "Bearer #{@access_token}"
      request["Content-Type"] = "application/json"
      request.body = {
        topic: meeting_title,
        type: 2,
        start_time: meeting.start_at.iso8601,
        duration: ((meeting.end_at - meeting.start_at) / 60).to_i,
        timezone: meeting.timezone,
        settings: {
          waiting_room: true,
          join_before_host: false
        }
      }.to_json

      response = Net::HTTP.start(CREATE_MEETING_URI.host, CREATE_MEETING_URI.port, use_ssl: true) { |http| http.request(request) }
      body = JSON.parse(response.body)
      raise(body["message"] || "Zoom meeting creation failed") unless response.is_a?(Net::HTTPSuccess)

      body
    end
  end
end
