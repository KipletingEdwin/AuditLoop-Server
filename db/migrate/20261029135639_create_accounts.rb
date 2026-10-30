
class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end
  end
end
