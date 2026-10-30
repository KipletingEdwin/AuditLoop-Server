class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.references :account, null: false, foreign_key: true
      t.string :external_id
      t.string :email
      t.string :name

      t.timestamps
    end
  end
end
