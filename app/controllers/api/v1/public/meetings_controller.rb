module Api
  module V1
    module Public
      class MeetingsController < ApplicationController
        def create
          attrs = meeting_params
          idempotency_key = attrs[:idempotency_key].presence || request.headers["Idempotency-Key"].presence || SecureRandom.uuid

          existing = Meeting.find_by(idempotency_key: idempotency_key)
          if existing.present?
            render json: serialize(existing), status: :ok
            return
          end

          meeting = Meeting.new(attrs.merge(idempotency_key: idempotency_key, status: "tentative"))

          unless Booking::AvailabilityService.new(
            timezone: meeting.timezone,
            days: 60
          ).slot_available?(meeting.start_at, meeting.end_at)
            render json: { error: "Requested slot is no longer available." }, status: :unprocessable_entity
            return
          end

          if meeting.save
            ProvisionMeetingJob.perform_later(meeting.id)
            render json: serialize(meeting), status: :accepted
          else
            render json: { errors: meeting.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def meeting_params
          params.require(:meeting).permit(:name, :email, :timezone, :start_at, :end_at, :topic, :notes, :idempotency_key)
        end

        def serialize(meeting)
          meeting.as_json(
            only: %i[id name email timezone start_at end_at status topic notes zoom_join_url google_event_id created_at updated_at]
          )
        end
      end
    end
  end
end
