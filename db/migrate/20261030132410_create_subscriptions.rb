
class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :plan_name, null: false
      t.integer :amount_cents, null: false
      t.string :status, null: false
      t.datetime :canceled_at
      t.timestamps

      t.check_constraint "status IN ('active','canceled','past_due')", name: "subscriptions_status_valid"
      t.check_constraint "amount_cents >= 0", name: "subscriptions_amount_nonneg"
    end
    add_index :subscriptions, [:account_id, :external_id], unique: true
  end
end
