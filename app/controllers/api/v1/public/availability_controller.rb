module Api
  module V1
    module Public
      class AvailabilityController < ApplicationController
        def index
          timezone = params[:timezone].presence || "UTC"
          days = params[:days].to_i
          days = 14 if days <= 0
          payload = Booking::AvailabilityService.new(timezone: timezone, days: [days, 30].min).call
          slots = payload[:days].flat_map { |day| day[:slots] }

          render json: {
            timezone: payload[:timezone],
            days: payload[:days],
            slots: slots
          }
        end
      end
    end
  end
end
