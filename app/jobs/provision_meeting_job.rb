class ProvisionMeetingJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 5, wait: :polynomially_longer

  def perform(meeting_id)
    meeting = Meeting.find(meeting_id)
    return if meeting.status == "cancelled"
    return if meeting.status == "scheduled"

    google_access_token = Integrations::GoogleAccessTokenService.new.call
    zoom_integration = OauthIntegration.active.find_by(provider: "zoom")

    raise "Google integration missing" if google_access_token.blank?
    raise "Zoom integration missing" if zoom_integration.blank?
    raise "Zoom integration token expired" if zoom_integration.expired?

    zoom_payload = Integrations::ZoomClient.new(access_token: zoom_integration.access_token).create_meeting!(meeting: meeting)
    meeting.update!(
      zoom_join_url: zoom_payload["join_url"],
      zoom_meeting_id: zoom_payload["id"].to_s
    )

    google_payload = Integrations::GoogleCalendarClient.new(access_token: google_access_token).create_event!(
      meeting: meeting,
      zoom_join_url: meeting.zoom_join_url
    )

    meeting.update!(
      status: "scheduled",
      google_event_id: google_payload["id"],
      provisioned_at: Time.current
    )
    MeetingMailer.confirmation_email(meeting).deliver_later
  rescue StandardError => e
    meeting&.update(status: "failed", notes: [meeting.notes, "Provisioning error: #{e.message}"].compact.join("\n"))
    raise
  end
end
