
class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.references :account, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :email, null: false
      t.string :name
      t.timestamps
    end
    add_index :customers, [:account_id, :external_id], unique: true
    add_index :customers, [:account_id, :email]
  end
end
