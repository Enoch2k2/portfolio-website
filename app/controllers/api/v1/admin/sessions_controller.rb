module Api
  module V1
    module Admin
      class SessionsController < ApplicationController
        def create
          email = params.require(:email).to_s.downcase
          password = params.require(:password).to_s

          expected_email = ENV.fetch("ADMIN_LOGIN_EMAIL", "")
          expected_password = ENV.fetch("ADMIN_LOGIN_PASSWORD", "")
          token = ENV.fetch("ADMIN_API_TOKEN", "")

          valid_email = expected_email.present? && email == expected_email.downcase
          valid_password = expected_password.present? && ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
          valid_token = token.present?

          unless valid_email && valid_password && valid_token
            render json: { error: "Invalid credentials" }, status: :unauthorized
            return
          end

          user = User.find_or_initialize_by(email: email)
          user.name = email.split("@").first.titleize if user.name.blank?
          user.role = "admin"
          user.active = true
          user.save!

          render json: { token: token, user: user.as_json(only: %i[id email name role]) }, status: :ok
        end
      end
    end
  end
end
