
# What the agent said. Immutable once created; human decisions live in Review.
class Proposal < ApplicationRecord
  include AccountScoped

  ACTIONS = %w[refund partial_refund no_action escalate].freeze
  MONEY_ACTIONS = %w[refund partial_refund].freeze

  belongs_to :ticket
  belongs_to :agent_run
  belongs_to :charge, optional: true
  has_one :review
  has_one :refund

  validates :action, inclusion: { in: ACTIONS }
  validates :reasoning, presence: true
  validates :confidence, numericality: { in: 0..1 }, allow_nil: true
  validates :charge, presence: true, if: :moves_money?
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }, if: :moves_money?

  def moves_money? = action.in?(MONEY_ACTIONS)

  def policy_passed? = policy_result["passed"] == true

  def readonly? = persisted? || super
end