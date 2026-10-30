
class AgentRun < ApplicationRecord
  include AccountScoped

  STATUSES = %w[running completed failed].freeze

  belongs_to :ticket
  has_many :tool_calls, -> { order(:position) }
  has_many :proposals

  validates :llm_model, :prompt_version, :started_at, presence: true
  validates :status, inclusion: { in: STATUSES }
end