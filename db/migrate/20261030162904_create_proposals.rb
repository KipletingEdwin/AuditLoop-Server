
class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals do |t|
      t.references :account, null: false, foreign_key: true
      t.references :ticket, null: false, foreign_key: true
      t.references :agent_run, null: false, foreign_key: true
      t.string :action, null: false
      t.references :charge, foreign_key: true # nullable: no_action / escalate
      t.integer :amount_cents
      t.string :currency, default: "usd"
      t.text :reasoning, null: false
      t.decimal :confidence, precision: 3, scale: 2
      t.jsonb :evidence, null: false, default: []
      t.jsonb :policy_result, null: false, default: {}
      t.timestamps

      t.check_constraint "action IN ('refund','partial_refund','no_action','escalate')", name: "proposals_action_valid"
      t.check_constraint "confidence IS NULL OR (confidence >= 0 AND confidence <= 1)", name: "proposals_confidence_range"
      # money-moving proposals must name a charge and a positive amount
      t.check_constraint "action NOT IN ('refund','partial_refund') OR (charge_id IS NOT NULL AND amount_cents > 0)",
                        name: "proposals_refund_has_charge_and_amount"
    end
  end
end
