
require "test_helper"

class RefundTest < ActiveSupport::TestCase
  setup do
    @w = build_world
    @proposal = build_proposal(@w)
  end

  def refund(key, cents, status: "pending")
    Refund.new(account: @w[:account], charge: @w[:charge], proposal: @proposal,
               idempotency_key: key, amount_cents: cents, status: status)
  end

  test "idempotency key is derived from the proposal" do
    assert_equal "refund-proposal-#{@proposal.id}", Refund.key_for(@proposal)
  end

  test "database refuses refunds that exceed the charge" do
    refund("k1", 3000).save!
    refund("k2", 2000).save! # exactly reaches the 5000 limit

    assert_raises(ActiveRecord::CheckViolation) { refund("k3", 1).save! }
  end

  test "failed refunds do not count toward the cap" do
    refund("k1", 5000, status: "failed").save!
    assert refund("k2", 5000).save!
  end

  test "database refuses a duplicate idempotency key even without validations" do
    refund("k1", 1000).save!
    assert_raises(ActiveRecord::RecordNotUnique) { refund("k1", 1000).save!(validate: false) }
  end
end