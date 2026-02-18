module Booking
  class AvailabilityService
    SLOT_MINUTES = 30

    def initialize(timezone:, days:, access_token_fetcher: nil, calendar_client_factory: nil)
      @timezone = timezone
      @days = [days.to_i, 1].max
      @access_token_fetcher = access_token_fetcher
      @calendar_client_factory = calendar_client_factory
    end

    def call
      now = Time.current.in_time_zone(@timezone)
      days = (0...lookahead_days).map { |offset| now.to_date + offset }
      slots = build_slots_for_days(days, now: now)
      {
        timezone: @timezone,
        days: group_by_day(slots)
      }
    end

    def slot_available?(start_at, end_at)
      desired_start = start_at.utc
      desired_end = end_at.utc
      return false if desired_end <= desired_start
      return false if desired_start < minimum_bookable_start_utc
      return false if outside_business_hours?(desired_start.in_time_zone(@timezone), desired_end.in_time_zone(@timezone))
      return false if overlaps_meeting?(desired_start, desired_end)

      busy_windows = google_busy_windows_for_range(
        time_min: desired_start.beginning_of_day,
        time_max: desired_start.end_of_day
      )
      !overlaps_busy_windows?(desired_start, desired_end, busy_windows)
    end

    private

    def lookahead_days
      [@days, 60].min
    end

    def build_slots_for_days(days, now:)
      return [] if days.empty?

      utc_start = days.first.in_time_zone(@timezone).beginning_of_day.utc
      utc_end = days.last.in_time_zone(@timezone).end_of_day.utc
      busy_windows = google_busy_windows_for_range(time_min: utc_start, time_max: utc_end)
      post_meeting_buffer = booking_post_meeting_buffer_hours.hours
      local_meetings = Meeting.where.not(status: "cancelled")
                             .where("start_at < ? AND end_at > ?", utc_end, utc_start - post_meeting_buffer)
                             .pluck(:start_at, :end_at)
                             .map { |start_at, end_at| { start_at: start_at.utc, end_at: end_at.utc + post_meeting_buffer } }

      slots = []
      days.each do |day|
        next unless day_allowed?(day)

        day_start = Time.use_zone(@timezone) do
          Time.zone.local(day.year, day.month, day.day, booking_start_hour, 0, 0)
        end
        day_end = Time.use_zone(@timezone) do
          Time.zone.local(day.year, day.month, day.day, booking_end_hour, 0, 0)
        end
        next if day_end <= day_start

        slot_start = day_start
        while (slot_start + SLOT_MINUTES.minutes) <= day_end
          slot_end = slot_start + SLOT_MINUTES.minutes
          utc_slot_start = slot_start.utc
          utc_slot_end = slot_end.utc
          if utc_slot_start >= minimum_bookable_start_utc(now.utc) &&
             !overlaps_windows?(utc_slot_start, utc_slot_end, busy_windows) &&
             !overlaps_windows?(utc_slot_start, utc_slot_end, local_meetings)
            slots << { start_at: utc_slot_start.iso8601, end_at: utc_slot_end.iso8601 }
          end
          slot_start = slot_end
        end
      end
      slots
    end

    def group_by_day(slots)
      grouped = slots.group_by do |slot|
        Time.iso8601(slot[:start_at]).in_time_zone(@timezone).to_date.iso8601
      end
      grouped.keys.sort.map do |date|
        { date: date, slots: grouped[date] }
      end
    end

    def google_busy_windows_for_range(time_min:, time_max:)
      access_token = if @access_token_fetcher
        @access_token_fetcher.call
      else
        Integrations::GoogleAccessTokenService.new.call
      end
      return [] if access_token.blank?

      client = if @calendar_client_factory
        @calendar_client_factory.call(access_token)
      else
        Integrations::GoogleCalendarClient.new(access_token: access_token)
      end
      client.freebusy(time_min: time_min, time_max: time_max)
    rescue StandardError
      []
    end

    def overlaps_busy_windows?(start_at, end_at, busy_windows)
      overlaps_windows?(start_at, end_at, busy_windows)
    end

    def overlaps_windows?(start_at, end_at, windows)
      windows.any? do |window|
        window[:start_at] < end_at && window[:end_at] > start_at
      end
    end

    def overlaps_meeting?(start_at, end_at)
      post_meeting_buffer = booking_post_meeting_buffer_hours.hours
      meeting_windows = Meeting.where.not(status: "cancelled")
                               .where("start_at < ? AND end_at > ?", end_at, start_at - post_meeting_buffer)
                               .pluck(:start_at, :end_at)
                               .map { |meeting_start, meeting_end| { start_at: meeting_start.utc, end_at: meeting_end.utc + post_meeting_buffer } }
      overlaps_windows?(start_at, end_at, meeting_windows)
    end

    def outside_business_hours?(start_local, end_local)
      return true unless booking_weekdays.include?(start_local.wday)

      start_hour_ok = start_local.hour >= booking_start_hour
      end_hour_ok = end_local.hour < booking_end_hour || (end_local.hour == booking_end_hour && end_local.min.zero?)
      !(start_hour_ok && end_hour_ok)
    end

    def booking_start_hour
      ENV.fetch("BOOKING_DAY_START_HOUR", 9).to_i
    end

    def booking_end_hour
      ENV.fetch("BOOKING_DAY_END_HOUR", 17).to_i
    end

    def booking_weekdays
      ENV.fetch("BOOKING_WEEKDAYS", "1,2,3,4,5")
         .split(",")
         .map { |day| day.strip.to_i }
         .select { |day| day.between?(0, 6) }
    end

    def day_allowed?(day)
      booking_weekdays.include?(day.wday)
    end

    def minimum_bookable_start_utc(reference_time = Time.current.utc)
      reference_time + booking_min_notice_hours.hours
    end

    def booking_min_notice_hours
      [ENV.fetch("BOOKING_MIN_NOTICE_HOURS", 24).to_i, 0].max
    end

    def booking_post_meeting_buffer_hours
      [ENV.fetch("BOOKING_POST_MEETING_BUFFER_HOURS", 2).to_i, 0].max
    end

  end
end
