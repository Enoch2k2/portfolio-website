class SiteSetting < ApplicationRecord
  HERO_PHOTO_KEY = "hero_photo".freeze
  RESUME_KEY = "resume".freeze

  has_one_attached :image

  validates :key, presence: true, uniqueness: true

  def self.hero_photo
    find_or_create_by!(key: HERO_PHOTO_KEY)
  end

  def self.resume_document
    find_or_create_by!(key: RESUME_KEY)
  end

  def resume_text
    value.to_s.presence
  end
end
