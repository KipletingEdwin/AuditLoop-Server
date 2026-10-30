
module Factory
  def build_world
    account = Account.create!(name: "Acme")
    customer = account.customers.create!(external_id: "cus_1", email: "c@example.com", name: "Casey")
    charge = account.charges.create!(customer: customer, external_id: "ch_1", amount_cents: 5000,
                                     status: "succeeded", charged_at: 1.day.ago)
    ticket = account.tickets.create!(customer: customer, from_email: customer.email,
                                     subject: "Charged twice", body: "Please refund", received_at: Time.current)
    run = account.agent_runs.create!(ticket: ticket, llm_model: "test-model", prompt_version: "v0",
                                     started_at: Time.current)
    manager = account.users.create!(email_address: "manager@acme.test", password: "password123", role: "manager")
    reviewer = account.users.create!(email_address: "reviewer@acme.test", password: "password123", role: "reviewer")

    { account: account, customer: customer, charge: charge, ticket: ticket,
      run: run, manager: manager, reviewer: reviewer }
  end

  def build_proposal(world, **attrs)
    defaults = { account: world[:account], ticket: world[:ticket], agent_run: world[:run],
                 action: "refund", charge: world[:charge], amount_cents: 5000,
                 reasoning: "Duplicate charge found", confidence: 0.9 }
    Proposal.create!(defaults.merge(attrs))
  end
end