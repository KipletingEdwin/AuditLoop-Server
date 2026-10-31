
module AgentTools
  class ListCharges < Base
    def self.description = "List a customer's most recent charges (newest first), including how much of each is still refundable."

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

      charges = account.charges.where(customer: customer).order(charged_at: :desc).limit(20)
      {
        charges: charges.map do |c|
          { id: c.id, external_id: c.external_id, amount_cents: c.amount_cents, currency: c.currency,
            status: c.status, description: c.description, charged_at: c.charged_at.iso8601,
            subscription_id: c.subscription_id, refundable_cents: c.refundable_cents }
        end
      }
    end
  end
end