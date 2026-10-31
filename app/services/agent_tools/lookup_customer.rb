
module AgentTools
  class LookupCustomer < Base
    def self.description = "Find a customer by email address. Returns found: false if no customer matches."

    def self.input_schema
      {
        type: "object",
        properties: { email: { type: "string", description: "The customer's email address" } },
        required: ["email"]
      }
    end

    def call(input)
      email = input[:email].to_s.strip.downcase
      return { error: "email is required" } if email.blank?

      customer = account.customers.find_by(email: email)
      return { found: false } unless customer

      { found: true, customer: { id: customer.id, external_id: customer.external_id,
                                 email: customer.email, name: customer.name } }
    end
  end
end