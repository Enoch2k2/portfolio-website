module Api
  module V1
    module Admin
      class MeetingsController < BaseController
        def index
          meetings = Meeting.order(start_at: :desc).limit(200)
          render json: meetings
        end

        def show
          render json: Meeting.find(params[:id])
        end
      end
    end
  end
end
