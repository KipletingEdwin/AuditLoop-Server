
module AgentTools
  class Base
    class << self
      def tool_name = name.demodulize.underscore
      def definition = { name: tool_name, description: description, input_schema: input_schema }
    end

    def initialize(account)
      @account = account
    end

    private

    attr_reader :account
  end
end