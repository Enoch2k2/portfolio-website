class OauthIntegration < ApplicationRecord
  PROVIDERS = %w[google zoom].freeze

  validates :provider, inclusion: { in: PROVIDERS }, uniqueness: true

  scope :active, -> { where(active: true) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end
end
