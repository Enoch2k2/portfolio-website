class BlogPost < ApplicationRecord
  STATUSES = %w[draft scheduled published archived].freeze

  has_many :blog_post_tags, dependent: :destroy
  has_many :blog_tags, through: :blog_post_tags

  validates :title, :slug, :markdown_body, presence: true
  validates :slug, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :published, -> { where(status: "published").where("published_at <= ?", Time.current).order(published_at: :desc) }

  before_validation :normalize_slug
  before_save :sync_status_timestamps

  private

  def normalize_slug
    base = slug.presence || title
    self.slug = base.to_s.parameterize if base.present?
  end

  def sync_status_timestamps
    return unless status_changed?

    if status == "published" && published_at.blank?
      self.published_at = Time.current
    elsif status == "scheduled" && scheduled_for.present?
      self.published_at = scheduled_for
    end
  end
end
