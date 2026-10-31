
# The only things the agent can do. All read-only, all scoped to one account.
# There is deliberately no tool that issues a refund.
module AgentTools
  def self.all
    [LookupCustomer, ListCharges, GetSubscription, ListRefunds]
  end

  # Tool definitions in the shape LLM APIs expect.
  def self.definitions = all.map(&:definition)

  # Runs a tool by name. Unknown tools return an error instead of raising,
  # so a hallucinated tool name can't crash the run.
  def self.execute(account, tool_name, input)
    tool = all.find { |t| t.tool_name == tool_name.to_s }
    return { error: "Unknown tool: #{tool_name}" } unless tool

    tool.new(account).call(input.to_h.with_indifferent_access)
  end
end