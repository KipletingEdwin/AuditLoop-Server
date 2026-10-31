
require "test_helper"

class AgentToolsTest < ActiveSupport::TestCase
  setup { @w = build_world }

  test "lookup_customer matches regardless of email case" do
    result = AgentTools.execute(@w[:account], "lookup_customer", { "email" => " C@Example.com " })
    assert result[:found]
    assert_equal @w[:customer].id, result[:customer][:id]
  end

  test "lookup_customer only searches the current account" do
    other = Account.create!(name: "Other")
    other.customers.create!(external_id: "cus_o", email: "only-in-other@example.com")

    result = AgentTools.execute(@w[:account], "lookup_customer", { "email" => "only-in-other@example.com" })
    assert_equal false, result[:found]
  end

  test "list_charges includes the refundable balance" do
    result = AgentTools.execute(@w[:account], "list_charges", { "customer_id" => @w[:customer].id })
    assert_equal 1, result[:charges].size
    assert_equal 5000, result[:charges].first[:refundable_cents]
  end

  test "list_charges refuses another account's customer" do
    other = Account.create!(name: "Other")
    stranger = other.customers.create!(external_id: "cus_s", email: "s@example.com")

    result = AgentTools.execute(@w[:account], "list_charges", { "customer_id" => stranger.id })
    assert_equal "Customer not found", result[:error]
  end

  test "an unknown tool returns an error instead of raising" do
    assert_match(/Unknown tool/, AgentTools.execute(@w[:account], "issue_refund", {})[:error])
  end

  test "the agent has exactly four tools and none of them write" do
    assert_equal %w[get_subscription list_charges list_refunds lookup_customer],
                 AgentTools.definitions.map { |d| d[:name] }.sort
  end
end