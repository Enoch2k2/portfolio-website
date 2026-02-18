module Api
  module V1
    module Admin
      class BlogPostsController < BaseController
        def index
          posts = BlogPost.includes(:blog_tags).order(created_at: :desc)
          render json: posts.map { |post| serialize(post, include_body: true) }
        end

        def show
          render json: serialize(find_post, include_body: true)
        end

        def create
          post = BlogPost.new(blog_post_params.except(:tag_names))
          assign_tags(post)

          if post.save
            render json: serialize(post, include_body: true), status: :created
          else
            render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          post = find_post
          post.assign_attributes(blog_post_params.except(:tag_names))
          assign_tags(post)

          if post.save
            render json: serialize(post, include_body: true)
          else
            render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          find_post.destroy!
          head :no_content
        end

        private

        def find_post
          BlogPost.includes(:blog_tags).find(params[:id])
        end

        def blog_post_params
          params.require(:blog_post).permit(
            :title,
            :slug,
            :summary,
            :markdown_body,
            :status,
            :published_at,
            :scheduled_for,
            :seo_title,
            :seo_description,
            :og_image_url,
            tag_names: []
          )
        end

        def assign_tags(post)
          tags = blog_post_params[:tag_names].to_a.map(&:strip).reject(&:blank?).uniq
          post.blog_tags = tags.map { |name| BlogTag.find_or_create_by!(slug: name.parameterize) { |tag| tag.name = name } }
        end

        def serialize(post, include_body: false)
          data = post.as_json(
            only: %i[id title slug summary status published_at scheduled_for seo_title seo_description og_image_url created_at updated_at]
          )
          data[:markdown_body] = post.markdown_body if include_body
          data[:tag_names] = post.blog_tags.map(&:name)
          data
        end
      end
    end
  end
end
