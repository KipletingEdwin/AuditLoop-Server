
# Every tenant-owned model includes this. Controllers should always query through
# the current account (e.g. Current.account.tickets), never Ticket.find directly.
module AccountScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :account
  end
end