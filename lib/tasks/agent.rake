
namespace :agent do
  desc "Run the billing agent on one ticket: bin/rails 'agent:run[TICKET_ID]'"
  task :run, [:ticket_id] => :environment do |_, args|
    ticket = Ticket.find(args[:ticket_id])
    run = BillingAgent.new(ticket).run!

    puts "Run ##{run.id}: #{run.status} (#{run.input_tokens} in / #{run.output_tokens} out tokens)"
    run.tool_calls.each { |c| puts "  #{c.position}. #{c.name} #{c.input.to_json}" }

    if (p = run.proposals.first)
      puts "Proposal: #{p.action} #{p.amount_cents.inspect} cents on charge #{p.charge_id.inspect} (confidence #{p.confidence})"
      puts "Policy: #{p.policy_passed? ? 'PASSED' : 'FAILED'}"
      puts "Reasoning: #{p.reasoning}"
      p.evidence.each { |e| puts "  - #{e}" }
    end
    puts "Error: #{run.error}" if run.error
    puts "Ticket state: #{ticket.reload.state}"
  end
end