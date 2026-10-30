
class Ticket < ApplicationRecord
  include AccountScoped

  class InvalidTransition < StandardError; end

  STATES = %w[received investigating proposed pending_approval approved rejected executed failed].freeze

  # The only legal moves. Anything else raises.
  # There is no path from investigating/proposed to approved/executed:
  # a ticket must pass through pending_approval, and only a human review gets it out.
  TRANSITIONS = {
    "received"         => %w[investigating],
    "investigating"    => %w[proposed failed],
    "proposed"         => %w[pending_approval failed],
    "pending_approval" => %w[approved rejected],
    "approved"         => %w[executed failed],
    "failed"           => %w[investigating], # retry
    "rejected"         => [],
    "executed"         => []
  }.freeze

  belongs_to :customer, optional: true
  has_many :events

  validates :from_email, :subject, :body, :received_at, presence: true
  validates :state, inclusion: { in: STATES }

  # Locks the row, checks the transition, updates, and writes the audit event
  # in a single transaction. All state changes should go through here.
  def transition_to!(new_state, actor_type:, actor_id: nil, data: {})
    with_lock do
      unless TRANSITIONS.fetch(state, []).include?(new_state)
        raise InvalidTransition, "#{state} -> #{new_state} is not allowed"
      end

      from = state
      update!(state: new_state)
      Event.record!(
        ticket: self,
        name: "ticket.#{new_state}",
        actor_type: actor_type,
        actor_id: actor_id,
        data: data.merge(from: from, to: new_state)
      )
    end
  end
end