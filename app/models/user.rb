class User < ApplicationRecord
  ROLES = %w[admin].freeze

  validates :email, :name, presence: true
  validates :email, uniqueness: true
  validates :role, inclusion: { in: ROLES }
end
