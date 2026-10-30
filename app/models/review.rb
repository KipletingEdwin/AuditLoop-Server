
# A human decision about a proposal. Immutable, one per proposal.
class Review < ApplicationRecord
  include AccountScoped

  DECISIONS = %w[approved rejected].freeze

  belongs_to :proposal
  belongs_to :user

  before_validation :fill_defaults

  validates :decision, inclusion: { in: DECISIONS }
  validates :reviewed_at, presence: true
  validates :rejection_reason, presence: true, if: :rejected?
  validates :final_amount_cents, numericality: { only_integer: true, greater_than: 0 },
                                 if: -> { approved? && proposal&.moves_money? }
  validate :reviewer_may_approve
  validate :same_account

  def approved? = decision == "approved"
  def rejected? = decision == "rejected"
  def edited? = approved? && proposal.moves_money? && final_amount_cents != proposal.amount_cents

  def readonly? = persisted? || super

  private

  def fill_defaults
    self.account_id ||= proposal&.account_id
    self.final_amount_cents ||= proposal&.amount_cents if approved?
  end

  def reviewer_may_approve
    errors.add(:user, "is not allowed to review proposals") unless user&.can_approve?
  end

  def same_account
    return unless proposal && user
    errors.add(:base, "reviewer and proposal must share an account") unless user.account_id == proposal.account_id
  end
end