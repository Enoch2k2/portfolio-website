# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.
#
# Read more: https://github.com/cyu/rack-cors
frontend_origins = ENV.fetch("FRONTEND_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173")
                         .split(",")
                         .map(&:strip)
                         .reject(&:empty?)

frontend_origin_patterns = ENV.fetch("FRONTEND_ORIGIN_PATTERNS", "")
                              .split(",")
                              .map(&:strip)
                              .reject(&:empty?)
                              .filter_map do |pattern|
                                Regexp.new(pattern)
                              rescue RegexpError
                                nil
                              end

# Allow temporary ngrok frontend URLs during local development.
if Rails.env.development?
  frontend_origin_patterns << %r{\Ahttps://[a-z0-9-]+\.ngrok-free\.(app|dev)\z}
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*frontend_origins, *frontend_origin_patterns)

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head]
  end
end
