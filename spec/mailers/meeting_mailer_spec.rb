require 'rails_helper'

RSpec.describe MeetingMailer do
  describe '#confirmation_email' do
    it 'includes date, time, and zoom link' do
      meeting = Meeting.create!(
        name: 'Test User',
        email: 'test@example.com',
        timezone: 'America/New_York',
        start_at: Time.utc(2026, 2, 20, 15, 0, 0),
        end_at: Time.utc(2026, 2, 20, 15, 30, 0),
        topic: 'Discovery Call',
        notes: 'Initial meeting',
        idempotency_key: SecureRandom.uuid,
        status: 'scheduled',
        zoom_join_url: 'https://zoom.us/j/1234567890'
      )

      email = described_class.confirmation_email(meeting)

      expect(email.to).to eq(['test@example.com'])
      expect(email.subject).to eq('Meeting confirmed: Discovery Call')
      expect(email.body.to_s).to include('Date:')
      expect(email.body.to_s).to include('Time:')
      expect(email.body.to_s).to include('Zoom: https://zoom.us/j/1234567890')
    end
  end
end
