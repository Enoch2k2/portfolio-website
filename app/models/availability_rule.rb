class AvailabilityRule < ApplicationRecord
  validates :weekday, inclusion: { in: 0..6 }
  validates :timezone, :start_time, :end_time, presence: true
  validate :end_after_start

  scope :active, -> { where(active: true) }

  private

  def end_after_start
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "must be after start time")
  end
end
