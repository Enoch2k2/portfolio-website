require 'rails_helper'

RSpec.describe 'Admin API' do
  let(:token) { 'test-admin-token' }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    ENV['ADMIN_API_TOKEN'] = token
    ENV['ADMIN_LOGIN_EMAIL'] = 'admin@example.com'
    ENV['ADMIN_LOGIN_PASSWORD'] = 'secret123'
  end

  it 'returns auth token for valid admin login' do
    post '/api/v1/admin/session', params: { email: 'admin@example.com', password: 'secret123' }

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload['token']).to eq(token)
  end

  it 'creates a blog post with valid auth token' do
    post '/api/v1/admin/blog_posts',
         params: {
           blog_post: {
             title: 'Admin Post',
             slug: 'admin-post',
             summary: 'summary',
             markdown_body: '# Body',
             status: 'draft',
             tag_names: %w[rails react]
           }
         },
         headers: auth_headers

    expect(response).to have_http_status(:created)
    payload = JSON.parse(response.body)
    expect(payload['title']).to eq('Admin Post')
    expect(payload['tag_names'].size).to eq(2)
  end

  it 'includes resume field in site content response' do
    get '/api/v1/admin/site_content', headers: auth_headers

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload).to have_key('hero_photo_url')
    expect(payload).to have_key('resume_url')
  end

  it 'requires a file for resume upload' do
    post '/api/v1/admin/site_content/resume', headers: auth_headers

    expect(response).to have_http_status(:unprocessable_content)
    payload = JSON.parse(response.body)
    expect(payload['error']).to eq('file is required')
  end

  it 'uploads a pdf resume and exposes resume_url' do
    file = Rack::Test::UploadedFile.new(
      Rails.root.join('spec/fixtures/files/sample_resume.pdf'),
      'application/pdf'
    )

    post '/api/v1/admin/site_content/resume',
         params: { file: file },
         headers: auth_headers

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload['resume_url']).to be_present
  end

  it 'rejects non-pdf resume upload' do
    file = Rack::Test::UploadedFile.new(
      Rails.root.join('spec/fixtures/files/sample_resume.txt'),
      'text/plain'
    )

    post '/api/v1/admin/site_content/resume',
         params: { file: file },
         headers: auth_headers

    expect(response).to have_http_status(:unprocessable_content)
    payload = JSON.parse(response.body)
    expect(payload['error']).to eq('resume must be a PDF file')
  end

  it 'removes uploaded resume document' do
    setting = SiteSetting.resume_document
    setting.image.attach(
      io: File.open(Rails.root.join('spec/fixtures/files/sample_resume.pdf')),
      filename: 'sample_resume.pdf',
      content_type: 'application/pdf'
    )

    delete '/api/v1/admin/site_content/resume', headers: auth_headers

    expect(response).to have_http_status(:no_content)
    expect(setting.reload.image).not_to be_attached
  end
end
