module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authenticate_admin!

        private

        def authenticate_admin!
          expected = ENV.fetch("ADMIN_API_TOKEN", "")
          provided = request.authorization.to_s.delete_prefix("Bearer ").strip

          if expected.blank? || provided.blank? || !ActiveSupport::SecurityUtils.secure_compare(provided, expected)
            render json: { error: "Unauthorized" }, status: :unauthorized
          end
        end
      end
    end
  end
end
