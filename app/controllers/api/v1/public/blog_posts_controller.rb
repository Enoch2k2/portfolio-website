module Api
  module V1
    module Public
      class BlogPostsController < ApplicationController
        def index
          posts = BlogPost.published.includes(:blog_tags)
          render json: posts.map { |post| serialize_post(post) }
        end

        def show
          post = BlogPost.published.includes(:blog_tags).find_by!(slug: params[:slug])
          render json: serialize_post(post, include_body: true)
        end

        private

        def serialize_post(post, include_body: false)
          payload = {
            id: post.id,
            title: post.title,
            slug: post.slug,
            summary: post.summary,
            status: post.status,
            published_at: post.published_at,
            seo_title: post.seo_title,
            seo_description: post.seo_description,
            og_image_url: post.og_image_url,
            tags: post.blog_tags.map { |tag| { id: tag.id, name: tag.name, slug: tag.slug } }
          }
          payload[:markdown_body] = post.markdown_body if include_body
          payload
        end
      end
    end
  end
end
