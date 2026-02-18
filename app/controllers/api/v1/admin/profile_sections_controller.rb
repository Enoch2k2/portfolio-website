module Api
  module V1
    module Admin
      class ProfileSectionsController < BaseController
        def index
          render json: ProfileSection.order(:position, :created_at).as_json
        end

        def show
          render json: find_section
        end

        def create
          section = ProfileSection.new(section_params)
          if section.save
            render json: section, status: :created
          else
            render json: { errors: section.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          section = find_section
          if section.update(section_params)
            render json: section
          else
            render json: { errors: section.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          find_section.destroy!
          head :no_content
        end

        private

        def find_section
          ProfileSection.find(params[:id])
        end

        def section_params
          params.require(:profile_section).permit(:key, :title, :markdown_body, :position, :published)
        end
      end
    end
  end
end
