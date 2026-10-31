
require "test_helper"

class RefundPolicyTest < ActiveSupport::TestCase
  setup do
    @w = build_world # one $50.00 charge belonging to the ticket's customer
    @policy = RefundPolicy.new(@w[:ticket])
  end

  def evaluate(**args) = @policy.evaluate(**{ action: "refund", charge_id: @w[:charge].id, amount_cents: 5000 }.merge(args))

  test "a valid full refund passes every rule" do
    assert evaluate.passed?
  end

  test "refunding more than the charge fails" do
    assert_includes evaluate(amount_cents: 5001).failed_rules, "within_refundable_balance"
  end

  test "another customer's charge fails" do
    other = @w[:account].customers.create!(external_id: "cus_2", email: "other@example.com")
    charge = @w[:account].charges.create!(customer: other, external_id: "ch_2", amount_cents: 5000,
                                          status: "succeeded", charged_at: 1.day.ago)
    assert_includes evaluate(charge_id: charge.id).failed_rules, "ticket_customer_matched"
  end

  test "a ticket with no matched customer cannot refund anything" do
    @w[:ticket].update!(customer: nil)
    assert_includes evaluate.failed_rules, "ticket_customer_matched"
  end

  test "a charge from another account is invisible" do
    other_account = Account.create!(name: "Other")
    other_customer = other_account.customers.create!(external_id: "cus_x", email: "x@example.com")
    charge = other_account.charges.create!(customer: other_customer, external_id: "ch_x", amount_cents: 5000,
                                          status: "succeeded", charged_at: 1.day.ago)
    assert_includes evaluate(charge_id: charge.id).failed_rules, "charge_exists_in_account"
  end

  test "a charge outside the refund window fails" do
    @w[:charge].update!(charged_at: 200.days.ago)
    assert_includes evaluate.failed_rules, "within_refund_window"
  end

  test "no_action needs no charge and passes" do
    assert @policy.evaluate(action: "no_action").passed?
  end

  test "earlier refunds reduce what can still be refunded" do
    proposal = build_proposal(@w)
    Refund.create!(account: @w[:account], charge: @w[:charge], proposal: proposal,
                   idempotency_key: "k1", amount_cents: 3000, status: "succeeded")

    assert_includes evaluate(amount_cents: 3000).failed_rules, "within_refundable_balance"
    assert evaluate(amount_cents: 2000).passed?
  end

  test "an unknown action fails" do
    assert_not @policy.evaluate(action: "wire_money").passed?
  end

  test "refunds over the maximum fail even when the charge is large enough" do
    big = @w[:account].charges.create!(customer: @w[:customer], external_id: "ch_big", amount_cents: 100_000,
                                       status: "succeeded", charged_at: 1.day.ago)
    assert_includes evaluate(charge_id: big.id, amount_cents: 60_000).failed_rules, "under_max_refund"
  end
end