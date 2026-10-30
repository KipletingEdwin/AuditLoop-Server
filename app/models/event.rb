
# Append-only audit log. Enforced twice: readonly? on persisted rows in Rails,
# and a Postgres trigger that rejects UPDATE/DELETE/TRUNCATE even from raw SQL.
class Event < ApplicationRecord
  include AccountScoped

  ACTOR_TYPES = %w[user agent system].freeze

  belongs_to :ticket, optional: true

  validates :name, presence: true
  validates :actor_type, inclusion: { in: ACTOR_TYPES }

  def self.record!(ticket:, name:, actor_type:, actor_id: nil, data: {})
    create!(account_id: ticket.account_id, ticket: ticket, name: name,
            actor_type: actor_type, actor_id: actor_id, data: data)
  end

  def readonly? = persisted? || super
end