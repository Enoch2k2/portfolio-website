require "test_helper"

module Booking
  class AvailabilityServiceTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::TimeHelpers

    test "filters out google busy windows from generated slots" do
      travel_to Time.utc(2026, 2, 18, 8, 0, 0) do
        busy_windows = [
          { start_at: Time.utc(2026, 2, 18, 10, 0, 0), end_at: Time.utc(2026, 2, 18, 11, 0, 0) }
        ]

        payload = service_with_busy_windows(busy_windows).call

        day = payload[:days].first
        assert_not_nil day

        slot_starts = day[:slots].map { |slot| Time.iso8601(slot[:start_at]).utc.hour }
        refute_includes slot_starts, 10
      end
    end

    test "slot_available returns false during google busy window" do
      busy_windows = [
        { start_at: Time.utc(2026, 2, 18, 14, 0, 0), end_at: Time.utc(2026, 2, 18, 15, 0, 0) }
      ]

      available = service_with_busy_windows(busy_windows).slot_available?(
        Time.utc(2026, 2, 18, 14, 0, 0),
        Time.utc(2026, 2, 18, 14, 30, 0)
      )

      assert_equal false, available
    end

    private

    def service_with_busy_windows(busy_windows)
      fake_client = Struct.new(:windows) do
        def freebusy(time_min:, time_max:)
          windows
        end
      end.new(busy_windows)

      AvailabilityService.new(
        timezone: "UTC",
        days: 1,
        access_token_fetcher: -> { "test-token" },
        calendar_client_factory: ->(_token) { fake_client }
      )
    end
  end
end
