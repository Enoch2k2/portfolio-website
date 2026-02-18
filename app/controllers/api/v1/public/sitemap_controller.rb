module Api
  module V1
    module Public
      class SitemapController < ApplicationController
        def index
          host = ENV.fetch("PUBLIC_APP_URL", "http://localhost:5173")
          posts_xml = BlogPost.published.limit(500).map do |post|
            <<~XML
              <url>
                <loc>#{host}/blog/#{post.slug}</loc>
                <lastmod>#{post.updated_at.utc.iso8601}</lastmod>
              </url>
            XML
          end.join

          render xml: <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
              <url>
                <loc>#{host}</loc>
              </url>
              #{posts_xml}
            </urlset>
          XML
        end
      end
    end
  end
end
