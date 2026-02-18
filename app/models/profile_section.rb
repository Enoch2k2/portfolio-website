class ProfileSection < ApplicationRecord
  validates :key, :title, :markdown_body, presence: true
  validates :key, uniqueness: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :published, -> { where(published: true).order(:position, :created_at) }
end
