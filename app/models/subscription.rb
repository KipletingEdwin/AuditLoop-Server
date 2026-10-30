
class Subscription < ApplicationRecord
  include AccountScoped

  STATUSES = %w[active canceled past_due].freeze

  belongs_to :customer
  has_many :charges

  validates :external_id, :plan_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end