
# Hard rules every proposal must pass before a human sees it as valid.
# Plain Ruby so it's easy to test and, later, to make per-account configurable.
class RefundPolicy
  MAX_REFUND_CENTS = 50_000 # $500
  REFUND_WINDOW = 120.days

  Result = Struct.new(:checks) do
    def passed? = checks.all? { |c| c[:passed] }
    def failed_rules = checks.reject { |c| c[:passed] }.map { |c| c[:rule] }
    def to_h = { passed: passed?, checks: checks }
  end

  def initialize(ticket)
    @ticket = ticket
  end

  def evaluate(action:, charge_id: nil, amount_cents: nil)
    checks = [check("known_action", Proposal::ACTIONS.include?(action), "action is #{action.inspect}")]
    return Result.new(checks) unless Proposal::MONEY_ACTIONS.include?(action)

    charge = @ticket.account.charges.find_by(id: charge_id)
    checks << check("charge_exists_in_account", charge.present?, "charge_id=#{charge_id.inspect}")

    valid_amount = amount_cents.is_a?(Integer) && amount_cents.positive?
    checks << check("amount_is_positive_integer", valid_amount, "amount_cents=#{amount_cents.inspect}")
    return Result.new(checks) unless charge && valid_amount

    checks << check("ticket_customer_matched",
                    @ticket.customer_id.present? && charge.customer_id == @ticket.customer_id,
                    "ticket customer=#{@ticket.customer_id.inspect}, charge customer=#{charge.customer_id}")
    checks << check("charge_succeeded", charge.status == "succeeded", "charge status is #{charge.status}")
    checks << check("within_refund_window", charge.charged_at >= REFUND_WINDOW.ago,
                    "charged #{charge.charged_at.to_date}, window is #{REFUND_WINDOW.in_days.to_i} days")
    checks << check("within_refundable_balance", amount_cents <= charge.refundable_cents,
                    "requested #{amount_cents}, refundable #{charge.refundable_cents}")
    checks << check("under_max_refund", amount_cents <= MAX_REFUND_CENTS,
                    "requested #{amount_cents}, maximum #{MAX_REFUND_CENTS}")

    Result.new(checks)
  end

  private

  def check(rule, passed, detail) = { rule: rule, passed: passed, detail: detail }
end