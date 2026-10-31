
module AgentTools
  class ListRefunds < Base
    def self.description = "List refunds already issued against a charge."

    def self.input_schema
      {
        type: "object",
        properties: { charge_id: { type: "integer", description: "The charge's id from list_charges" } },
        required: ["charge_id"]
      }
    end

    def call(input)
      charge = account.charges.find_by(id: input[:charge_id])
      return { error: "Charge not found" } unless charge

      {
        refunds: account.refunds.where(charge: charge).order(:created_at).map do |r|
          { id: r.id, amount_cents: r.amount_cents, status: r.status, created_at: r.created_at.iso8601 }
        end
      }
    end
  end
end