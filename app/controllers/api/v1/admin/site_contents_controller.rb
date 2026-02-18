module Api
  module V1
    module Admin
      class SiteContentsController < BaseController
        include Rails.application.routes.url_helpers

        def show
          hero_setting = SiteSetting.hero_photo
          resume_setting = SiteSetting.resume_document
          render json: {
            hero_photo_url: hero_photo_url(hero_setting),
            resume_url: resume_url(resume_setting),
            resume_text: formatted_resume_text(resume_setting.resume_text)
          }
        end

        def hero_photo
          setting = SiteSetting.hero_photo
          file = params[:image]
          if file.blank?
            render json: { error: "image is required" }, status: :unprocessable_entity
            return
          end

          setting.image.attach(file)
          render json: { hero_photo_url: hero_photo_url(setting) }, status: :ok
        end

        def resume
          setting = SiteSetting.resume_document
          file = params[:file]
          if file.blank?
            render json: { error: "file is required" }, status: :unprocessable_content
            return
          end

          unless pdf_file?(file)
            render json: { error: "resume must be a PDF file" }, status: :unprocessable_content
            return
          end

          setting.image.attach(file)
          raw_resume_text = extracted_resume_text(setting)
          formatted_text = formatted_resume_text(raw_resume_text)
          setting.update!(value: formatted_text)
          render json: { resume_url: resume_url(setting), resume_text: formatted_text }, status: :ok
        end

        def destroy_hero_photo
          setting = SiteSetting.hero_photo
          setting.image.purge if setting.image.attached?

          head :no_content
        end

        def destroy_resume
          setting = SiteSetting.resume_document
          setting.image.purge if setting.image.attached?
          setting.update!(value: nil)

          head :no_content
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

        def pdf_file?(file)
          file.content_type.in?(%w[application/pdf application/x-pdf]) || file.original_filename.to_s.downcase.end_with?(".pdf")
        end

        def extracted_resume_text(setting)
          return nil unless setting.image.attached?

          Pdf::ResumeTextExtractor.new(file_blob: setting.image.blob).call
        end

        def formatted_resume_text(raw_text)
          Pdf::ResumeTextFormatter.new(raw_text: raw_text).call
        end
      end
    end
  end
end
