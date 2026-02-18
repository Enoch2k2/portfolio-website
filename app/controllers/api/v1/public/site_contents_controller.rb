module Api
  module V1
    module Public
      class SiteContentsController < ApplicationController
        include Rails.application.routes.url_helpers

        def show
          hero_setting = SiteSetting.hero_photo
          resume_setting = SiteSetting.resume_document
          render json: {
            hero_photo_url: hero_photo_url(hero_setting),
            resume_url: resume_url(resume_setting)
          }
        end

        private

        def hero_photo_url(setting)
          return nil unless setting.image.attached?

          rails_blob_url(setting.image, host: request.base_url)
        end

        def resume_url(setting)
          return nil unless setting.image.attached?

          rails_blob_url(setting.image, host: request.base_url)
        end
      end
    end
  end
end
