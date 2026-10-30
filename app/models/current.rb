
class Current < ActiveSupport::CurrentAttributes
  attribute :user
  delegate :account, to: :user, allow_nil: true
end