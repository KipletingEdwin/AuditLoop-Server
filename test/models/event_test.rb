
require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Acme")
    @event = Event.create!(account: @account, actor_type: "system", name: "test.event")
  end

  test "ActiveRecord refuses to update or destroy" do
    assert_raises(ActiveRecord::ReadOnlyRecord) { @event.update!(name: "changed") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { @event.destroy }
  end

  test "database refuses raw UPDATE, DELETE and TRUNCATE" do
    conn = Event.connection
    assert_raises(ActiveRecord::StatementInvalid) { conn.execute("UPDATE events SET name = 'x'") }
    assert_raises(ActiveRecord::StatementInvalid) { conn.execute("DELETE FROM events") }
    assert_raises(ActiveRecord::StatementInvalid) { conn.execute("TRUNCATE events") }
  end
end