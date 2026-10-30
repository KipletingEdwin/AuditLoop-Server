
class CreateTickets < ActiveRecord::Migration[8.1]
  STATES = %w[received investigating proposed pending_approval approved rejected executed failed].freeze

  def change
    create_table :tickets do |t|
      t.references :account, null: false, foreign_key: true
      t.references :customer, foreign_key: true # nullable: sender may not match a customer
      t.string :from_email, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.datetime :received_at, null: false
      t.string :state, null: false, default: "received"
      t.timestamps

      t.check_constraint "state IN (#{STATES.map { |s| "'#{s}'" }.join(',')})", name: "tickets_state_valid"
    end
    add_index :tickets, [:account_id, :state]
  end
end
