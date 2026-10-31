
module AgentTools
  class GetSubscription < Base
    def self.description = "List a customer's subscriptions with plan, price, status and cancellation date."

    def self.input_schema
      {
        type: "object",
        properties: { customer_id: { type: "integer", description: "The customer's id from lookup_customer" } },
        required: ["customer_id"]
      }
    end

    def call(input)
      customer = account.customers.find_by(id: input[:customer_id])
      return { error: "Customer not found" } unless customer

      {
        subscriptions: account.subscriptions.where(customer: customer).map do |s|
          { id: s.id, external_id: s.external_id, plan_name: s.plan_name, amount_cents: s.amount_cents,
            status: s.status, canceled_at: s.canceled_at&.iso8601 }
        end
      }
    end
  end
end