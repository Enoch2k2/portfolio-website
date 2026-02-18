require 'rails_helper'

module Booking
  RSpec.describe AvailabilityService do
    def service_with_busy_windows(busy_windows)
      fake_client = Struct.new(:windows) do
        def freebusy(time_min:, time_max:)
          windows
        end
      end.new(busy_windows)

      described_class.new(
        timezone: 'UTC',
        days: 2,
        access_token_fetcher: -> { 'test-token' },
        calendar_client_factory: ->(_token) { fake_client }
      )
    end

    it 'filters out google busy windows from generated slots' do
      travel_to Time.utc(2026, 2, 17, 8, 0, 0) do
        busy_windows = [
          { start_at: Time.utc(2026, 2, 18, 10, 0, 0), end_at: Time.utc(2026, 2, 18, 11, 0, 0) }
        ]

        payload = service_with_busy_windows(busy_windows).call
        day = payload[:days].first
        expect(day).not_to be_nil

        slot_starts = day[:slots].map { |slot| Time.iso8601(slot[:start_at]).utc.hour }
        expect(slot_starts).not_to include(10)
      end
    end

    it 'returns false for slot availability during a busy window' do
      travel_to Time.utc(2026, 2, 17, 8, 0, 0) do
        busy_windows = [
          { start_at: Time.utc(2026, 2, 18, 14, 0, 0), end_at: Time.utc(2026, 2, 18, 15, 0, 0) }
        ]

        available = service_with_busy_windows(busy_windows).slot_available?(
          Time.utc(2026, 2, 18, 14, 0, 0),
          Time.utc(2026, 2, 18, 14, 30, 0)
        )

        expect(available).to be(false)
      end
    end

    it 'does not return slots within the next 24 hours' do
      travel_to Time.utc(2026, 2, 18, 8, 0, 0) do
        payload = service_with_busy_windows([]).call
        starts = payload[:days].flat_map { |day| day[:slots].map { |slot| Time.iso8601(slot[:start_at]) } }

        expect(starts).to all(be >= Time.utc(2026, 2, 19, 8, 0, 0))
      end
    end

    it 'respects configured minimum notice hours from environment' do
      travel_to Time.utc(2026, 2, 18, 8, 0, 0) do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("BOOKING_MIN_NOTICE_HOURS", 24).and_return("48")

        payload = service_with_busy_windows([]).call
        starts = payload[:days].flat_map { |day| day[:slots].map { |slot| Time.iso8601(slot[:start_at]) } }

        expect(starts).to all(be >= Time.utc(2026, 2, 20, 8, 0, 0))
      end
    end

    it 'blocks new bookings for two hours after an existing meeting' do
      travel_to Time.utc(2026, 2, 17, 8, 0, 0) do
        Meeting.create!(
          name: "Existing Client",
          email: "client@example.com",
          timezone: "UTC",
          start_at: Time.utc(2026, 2, 18, 10, 0, 0),
          end_at: Time.utc(2026, 2, 18, 10, 30, 0),
          topic: "Consultation",
          notes: "Follow-up",
          status: "scheduled",
          idempotency_key: SecureRandom.uuid
        )

        service = service_with_busy_windows([])
        blocked = service.slot_available?(Time.utc(2026, 2, 18, 12, 0, 0), Time.utc(2026, 2, 18, 12, 30, 0))
        allowed_after_buffer = service.slot_available?(Time.utc(2026, 2, 18, 12, 30, 0), Time.utc(2026, 2, 18, 13, 0, 0))

        expect(blocked).to be(false)
        expect(allowed_after_buffer).to be(true)
      end
    end
  end
end
