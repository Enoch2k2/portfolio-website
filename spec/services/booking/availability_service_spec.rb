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
        days: 1,
        access_token_fetcher: -> { 'test-token' },
        calendar_client_factory: ->(_token) { fake_client }
      )
    end

    it 'filters out google busy windows from generated slots' do
      travel_to Time.utc(2026, 2, 18, 8, 0, 0) do
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
end
