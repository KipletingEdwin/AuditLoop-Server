
class Charge < ApplicationRecord
  include AccountScoped

  STATUSES = %w[succeeded pending failed].freeze

  belongs_to :customer
  belongs_to :subscription, optional: true

  validates :external_id, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
end