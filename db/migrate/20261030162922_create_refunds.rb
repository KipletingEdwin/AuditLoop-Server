
class CreateRefunds < ActiveRecord::Migration[8.1]
  def change
    create_table :refunds do |t|
      t.references :account, null: false, foreign_key: true
      t.references :charge, null: false, foreign_key: true
      t.references :proposal, null: false, foreign_key: true
      t.string :external_id
      t.integer :amount_cents, null: false
      t.string :status, null: false, default: "pending"
      t.string :idempotency_key, null: false
      t.timestamps

      t.check_constraint "amount_cents > 0", name: "refunds_amount_positive"
      t.check_constraint "status IN ('pending','succeeded','failed')", name: "refunds_status_valid"
    end
    add_index :refunds, :idempotency_key, unique: true
  end
end
