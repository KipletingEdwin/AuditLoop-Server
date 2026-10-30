
require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Acme")
    @ticket = Ticket.create!(account: @account, from_email: "a@example.com",
                             subject: "Charged twice", body: "Help", received_at: Time.current)
  end

  test "legal transition updates state and writes an event" do
    @ticket.transition_to!("investigating", actor_type: "system")

    assert_equal "investigating", @ticket.reload.state
    event = Event.find_by!(ticket: @ticket)
    assert_equal "ticket.investigating", event.name
    assert_equal "received", event.data["from"]
  end

  test "illegal transition raises and changes nothing" do
    assert_raises(Ticket::InvalidTransition) do
      @ticket.transition_to!("executed", actor_type: "system")
    end
    assert_equal "received", @ticket.reload.state
    assert_equal 0, Event.where(ticket: @ticket).count
  end

  test "agent path cannot reach approved without passing pending_approval" do
    %w[investigating proposed].each { |s| @ticket.transition_to!(s, actor_type: "agent") }

    assert_raises(Ticket::InvalidTransition) do
      @ticket.transition_to!("approved", actor_type: "agent")
    end
  end

  test "terminal states have no exits" do
    assert_empty Ticket::TRANSITIONS["rejected"]
    assert_empty Ticket::TRANSITIONS["executed"]
  end
end