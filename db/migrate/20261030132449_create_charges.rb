class CreateCharges < ActiveRecord::Migration[8.1]
  def change
    create_table :charges do |t|
      t.references :account, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :subscription, null: false, foreign_key: true
      t.string :external_id
      t.integer :amount_cents
      t.string :currency
      t.string :status
      t.string :description
      t.datetime :charged_at

      t.timestamps
    end
  end
end
