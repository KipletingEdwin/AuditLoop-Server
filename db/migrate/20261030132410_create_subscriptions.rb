class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :external_id
      t.string :plan_name
      t.integer :amount_cents
      t.string :status
      t.datetime :canceled_at

      t.timestamps
    end
  end
end
