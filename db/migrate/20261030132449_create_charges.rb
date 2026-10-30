
class CreateCharges < ActiveRecord::Migration[8.1]
  def change
    create_table :charges do |t|
      t.references :account, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :subscription, foreign_key: true
      t.string :external_id, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "usd"
      t.string :status, null: false
      t.string :description
      t.datetime :charged_at, null: false
      t.timestamps

      t.check_constraint "amount_cents > 0", name: "charges_amount_positive"
      t.check_constraint "status IN ('succeeded','pending','failed')", name: "charges_status_valid"
    end
    add_index :charges, [:account_id, :external_id], unique: true
  end
end
