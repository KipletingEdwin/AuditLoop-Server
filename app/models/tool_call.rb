
class ToolCall < ApplicationRecord
  include AccountScoped

  belongs_to :agent_run

  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end