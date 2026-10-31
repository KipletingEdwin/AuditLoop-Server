
# Plays back scripted API responses so agent tests are fast, free and deterministic.
class FakeAnthropicClient
  attr_reader :requests

  def initialize(*responses)
    @responses = responses
    @requests = []
  end

  def messages(**params)
    @requests << params
    @responses.shift or raise "FakeAnthropicClient ran out of scripted responses"
  end

  def self.tool_use(name, input)
    { "type" => "tool_use", "id" => "toolu_#{SecureRandom.hex(4)}", "name" => name, "input" => input }
  end

  def self.reply(*blocks)
    { "content" => blocks, "stop_reason" => "tool_use", "usage" => { "input_tokens" => 100, "output_tokens" => 50 } }
  end
end