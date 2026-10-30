
require "test_helper"

class ProposalTest < ActiveSupport::TestCase
  setup { @w = build_world }

  test "money-moving proposal needs a charge and an amount" do
    proposal = Proposal.new(account: @w[:account], ticket: @w[:ticket], agent_run: @w[:run],
                            action: "refund", reasoning: "x")
    assert_not proposal.valid?
    assert proposal.errors[:charge].any?
    assert proposal.errors[:amount_cents].any?
  end

  test "no_action needs neither charge nor amount" do
    proposal = build_proposal(@w, action: "no_action", charge: nil, amount_cents: nil)
    assert proposal.persisted?
  end

  test "a saved proposal cannot be changed" do
    proposal = build_proposal(@w)
    assert_raises(ActiveRecord::ReadOnlyRecord) { proposal.update!(amount_cents: 1) }
  end
end