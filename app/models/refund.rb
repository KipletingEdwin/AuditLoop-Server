
# Money that actually moved (or is moving). Created only by the execution service.
class Refund < ApplicationRecord
  include AccountScoped

  STATUSES = %w[pending succeeded failed].freeze

  belongs_to :charge
  belongs_to :proposal

  validates :idempotency_key, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }

  # One refund per proposal. Also pass this key to Stripe.
  def self.key_for(proposal) = "refund-proposal-#{proposal.id}"
end