module Integrations
  class GoogleAccessTokenService
    def call
      integration = OauthIntegration.active.find_by(provider: "google")
      return nil if integration.blank?

      return integration.access_token if integration.expires_at.blank? || integration.expires_at > Time.current
      return nil if integration.refresh_token.blank?

      refreshed = Oauth::GoogleTokenExchangeService.new(refresh_token: integration.refresh_token).refresh!
      integration.access_token = refreshed.fetch("access_token")
      integration.refresh_token = refreshed["refresh_token"] if refreshed["refresh_token"].present?
      integration.expires_at = Time.current + refreshed.fetch("expires_in", 3600).to_i.seconds
      integration.metadata = integration.metadata.merge(refreshed.except("access_token", "refresh_token"))
      integration.save!
      integration.access_token
    end
  end
end
