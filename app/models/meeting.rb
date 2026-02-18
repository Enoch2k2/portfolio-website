class Meeting < ApplicationRecord
  STATUSES = %w[tentative scheduled failed cancelled].freeze

  validates :name, :email, :timezone, :start_at, :end_at, :idempotency_key, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :idempotency_key, uniqueness: true
  validate :ends_after_start

  scope :upcoming, -> { where("start_at >= ?", Time.current).order(:start_at) }

  private

  def ends_after_start
    return if start_at.blank? || end_at.blank?
    return if end_at > start_at

    errors.add(:end_at, "must be after start time")
  end
end
