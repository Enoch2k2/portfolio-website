require 'rails_helper'

RSpec.describe 'Public API' do
  before do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
  end

  it 'returns published blog posts' do
    post = BlogPost.create!(
      title: 'Published Post',
      slug: 'published-post',
      summary: 'Summary',
      markdown_body: '# Hello',
      status: 'published',
      published_at: Time.current
    )

    get '/api/v1/public/blog_posts'

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload.any? { |item| item['slug'] == post.slug }).to be(true)
  end

  it 'creates a meeting request and enqueues provisioning' do
    travel_to Time.utc(2026, 2, 18, 8, 0, 0) do
      start_time = Time.utc(2026, 2, 19, 10, 0, 0)
      end_time = start_time + 30.minutes

      expect do
        post '/api/v1/public/meetings',
             params: {
               meeting: {
                 name: 'Test User',
                 email: 'test@example.com',
                 timezone: 'UTC',
                 start_at: start_time.iso8601,
                 end_at: end_time.iso8601,
                 topic: 'Discovery',
                 notes: 'Interested in collaboration'
               }
             }
      end.to have_enqueued_job(ProvisionMeetingJob).exactly(:once)

      expect(response).to have_http_status(:accepted)
      payload = JSON.parse(response.body)
      expect(payload['status']).to eq('tentative')
    end
  end

  it 'returns meeting status by id for public polling' do
    meeting = Meeting.create!(
      name: 'Polling User',
      email: 'polling@example.com',
      timezone: 'UTC',
      start_at: Time.utc(2026, 2, 25, 14, 0, 0),
      end_at: Time.utc(2026, 2, 25, 14, 30, 0),
      topic: 'Website Consultation',
      notes: 'Initial note',
      status: 'scheduled',
      zoom_join_url: 'https://zoom.us/j/123',
      idempotency_key: SecureRandom.uuid
    )

    get "/api/v1/public/meetings/#{meeting.id}"

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload['id']).to eq(meeting.id)
    expect(payload['status']).to eq('scheduled')
    expect(payload['zoom_join_url']).to eq('https://zoom.us/j/123')
  end

  it 'returns availability grouped by day' do
    get '/api/v1/public/availability', params: { timezone: 'UTC', days: 5 }

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload['timezone']).to eq('UTC')
    expect(payload['days']).to be_a(Array)
    expect(payload['slots']).to be_a(Array)
  end

  it 'returns public site content with resume field' do
    get '/api/v1/public/site_content'

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload).to have_key('hero_photo_url')
    expect(payload).to have_key('resume_url')
    expect(payload).to have_key('resume_text')
  end

  it 'returns resume_url when a resume has been uploaded' do
    setting = SiteSetting.resume_document
    setting.update!(value: 'Parsed resume text from upload')
    setting.image.attach(
      io: File.open(Rails.root.join('spec/fixtures/files/sample_resume.pdf')),
      filename: 'sample_resume.pdf',
      content_type: 'application/pdf'
    )

    get '/api/v1/public/site_content'

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload['resume_url']).to be_present
    expect(payload['resume_text']).to eq('Parsed resume text from upload')
  end
end
