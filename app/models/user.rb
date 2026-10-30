
class User < ApplicationRecord
  ROLES = %w[reviewer manager admin].freeze
  APPROVER_ROLES = %w[manager admin].freeze

  has_secure_password
  belongs_to :account
  has_many :refresh_tokens, dependent: :delete_all

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }

  def can_approve? = role.in?(APPROVER_ROLES)
end