require "net/http"

module Oauth
  class GoogleTokenExchangeService
    TOKEN_URI = URI("https://oauth2.googleapis.com/token")

    def initialize(code: nil, redirect_uri: nil, refresh_token: nil)
      @code = code
      @redirect_uri = redirect_uri
      @refresh_token = refresh_token
    end

    def call
      payload = {
        code: @code,
        client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
        client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
        redirect_uri: @redirect_uri,
        grant_type: "authorization_code"
      }
      perform_request(payload)
    end

    def refresh!
      payload = {
        refresh_token: @refresh_token,
        client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
        client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
        grant_type: "refresh_token"
      }
      perform_request(payload)
    end

    private

    def perform_request(payload)
      response = Net::HTTP.post_form(TOKEN_URI, payload)
      body = JSON.parse(response.body)
      raise(body["error_description"] || body["error"] || "Google token exchange failed") unless response.is_a?(Net::HTTPSuccess)

      body
    end
  end
end
