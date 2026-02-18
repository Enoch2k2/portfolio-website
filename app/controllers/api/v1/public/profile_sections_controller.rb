module Api
  module V1
    module Public
      class ProfileSectionsController < ApplicationController
        def index
          render json: ProfileSection.published.as_json(only: %i[id key title markdown_body position updated_at])
        end
      end
    end
  end
end
