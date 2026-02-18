class MeetingMailer < ApplicationMailer
  def confirmation_email(meeting)
    @meeting = meeting

    local_start = in_meeting_timezone(@meeting.start_at)
    local_end = in_meeting_timezone(@meeting.end_at)
    topic = @meeting.topic.presence || "Client Discovery Call"

    mail(
      to: @meeting.email,
      subject: "Meeting confirmed: #{topic}",
      body: <<~BODY
        Hi #{@meeting.name},

        Your meeting is confirmed.

        Topic: #{topic}
        Date: #{local_start.strftime("%A, %B %-d, %Y")}
        Time: #{local_start.strftime("%-I:%M %p")} - #{local_end.strftime("%-I:%M %p")} (#{meeting_timezone_name})
        Zoom: #{@meeting.zoom_join_url.presence || "Zoom link will be shared shortly."}

        Thanks,
        Enoch Griffith
      BODY
    )
  end

  private

  def in_meeting_timezone(time)
    zone = ActiveSupport::TimeZone[@meeting.timezone]
    time.in_time_zone(zone || Time.zone)
  end

  def meeting_timezone_name
    zone = ActiveSupport::TimeZone[@meeting.timezone]
    zone&.tzinfo&.name || @meeting.timezone
  end
end
