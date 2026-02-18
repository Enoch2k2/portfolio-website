require "net/http"

module Oauth
  class ZoomTokenExchangeService
    TOKEN_URI = URI("https://zoom.us/oauth/token")

    def initialize(code: nil, redirect_uri: nil, refresh_token: nil)
      @code = code
      @redirect_uri = redirect_uri
      @refresh_token = refresh_token
    end

    def call
      payload = {
        grant_type: "authorization_code",
        code: @code,
        redirect_uri: @redirect_uri
      }
      perform_request(payload)
    end

    def refresh!
      payload = {
        grant_type: "refresh_token",
        refresh_token: @refresh_token
      }
      perform_request(payload)
    end

    private

    def perform_request(payload)
      request = Net::HTTP::Post.new("#{TOKEN_URI.path}?#{URI.encode_www_form(payload)}")
      request.basic_auth(ENV.fetch("ZOOM_CLIENT_ID"), ENV.fetch("ZOOM_CLIENT_SECRET"))
      response = Net::HTTP.start(TOKEN_URI.host, TOKEN_URI.port, use_ssl: true) { |http| http.request(request) }
      body = JSON.parse(response.body)
      raise(body["reason"] || body["message"] || "Zoom token exchange failed") unless response.is_a?(Net::HTTPSuccess)

      body
    end
  end
end
