
require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    @w = build_world
    @proposal = build_proposal(@w)
  end

  def review(user:, **attrs)
    Review.new({ proposal: @proposal, user: user, decision: "approved", reviewed_at: Time.current }.merge(attrs))
  end

  test "a reviewer-role user cannot approve" do
    assert_not review(user: @w[:reviewer]).valid?
  end

  test "approval defaults the final amount to the proposed amount" do
    r = review(user: @w[:manager])
    r.save!
    assert_equal 5000, r.final_amount_cents
    assert_not r.edited?
  end

  test "changing the amount marks the review as edited" do
    r = review(user: @w[:manager], final_amount_cents: 3000)
    r.save!
    assert r.edited?
  end

  test "rejection requires a reason" do
    assert_not review(user: @w[:manager], decision: "rejected").valid?
    assert review(user: @w[:manager], decision: "rejected", rejection_reason: "Customer was charged correctly").valid?
  end

  test "a proposal can only be reviewed once" do
    review(user: @w[:manager]).save!
    assert_raises(ActiveRecord::RecordNotUnique) { review(user: @w[:manager]).save! }
  end
end