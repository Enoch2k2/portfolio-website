class BlogTag < ApplicationRecord
  has_many :blog_post_tags, dependent: :destroy
  has_many :blog_posts, through: :blog_post_tags

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  before_validation :normalize_slug

  private

  def normalize_slug
    base = slug.presence || name
    self.slug = base.to_s.parameterize if base.present?
  end
end
