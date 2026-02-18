module Api
  module V1
    module Admin
      module Integrations
        class OauthController < BaseController
          def status
            integrations = OauthIntegration.order(:provider).map do |item|
              {
                provider: item.provider,
                active: item.active,
                external_account_id: item.external_account_id,
                expires_at: item.expires_at,
                expired: item.expired?
              }
            end
            render json: { integrations: integrations }
          end

          def google_exchange
            token = Oauth::GoogleTokenExchangeService.new(code: params.require(:code), redirect_uri: params.require(:redirect_uri)).call
            render json: persist_integration!("google", token)
          rescue StandardError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def zoom_exchange
            token = Oauth::ZoomTokenExchangeService.new(code: params.require(:code), redirect_uri: params.require(:redirect_uri)).call
            render json: persist_integration!("zoom", token)
          rescue StandardError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def google_refresh
            integration = OauthIntegration.find_by!(provider: "google")
            token = Oauth::GoogleTokenExchangeService.new(refresh_token: integration.refresh_token).refresh!
            render json: persist_integration!("google", token, keep_refresh_token: true)
          rescue StandardError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def zoom_refresh
            integration = OauthIntegration.find_by!(provider: "zoom")
            token = Oauth::ZoomTokenExchangeService.new(refresh_token: integration.refresh_token).refresh!
            render json: persist_integration!("zoom", token, keep_refresh_token: true)
          rescue StandardError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          private

          def persist_integration!(provider, token_data, keep_refresh_token: false)
            integration = OauthIntegration.find_or_initialize_by(provider: provider)
            integration.access_token = token_data.fetch("access_token")
            integration.refresh_token = token_data["refresh_token"] || integration.refresh_token if keep_refresh_token || token_data["refresh_token"].present?
            integration.expires_at = Time.current + token_data.fetch("expires_in", 3600).to_i.seconds
            integration.external_account_id = token_data["account_id"] || token_data["scope"]
            integration.active = true
            integration.metadata = token_data.except("access_token", "refresh_token")
            integration.save!

            {
              provider: integration.provider,
              active: integration.active,
              expires_at: integration.expires_at,
              external_account_id: integration.external_account_id
            }
          end
        end
      end
    end
  end
end
