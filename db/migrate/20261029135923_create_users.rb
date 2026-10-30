
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :account, null: false, foreign_key: true
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "reviewer"
      t.timestamps

      t.check_constraint "role IN ('reviewer','manager','admin')", name: "users_role_valid"
    end
    add_index :users, :email_address, unique: true
  end
end
