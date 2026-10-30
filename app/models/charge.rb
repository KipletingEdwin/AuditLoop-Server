
class Charge < ApplicationRecord
  include AccountScoped
  has_many :refunds

# Cents still refundable. The database trigger is the real enforcement;
# this is for the policy module and the review UI.
def refundable_cents
  amount_cents - refunds.where.not(status: "failed").sum(:amount_cents)
end

  STATUSES = %w[succeeded pending failed].freeze

  belongs_to :customer
  belongs_to :subscription, optional: true

  validates :external_id, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
end