
class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :account, null: false, foreign_key: true
      t.references :ticket, foreign_key: true
      t.string :actor_type, null: false
      t.bigint :actor_id
      t.string :name, null: false
      t.jsonb :data, null: false, default: {}
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" } # no updated_at: rows never change

      t.check_constraint "actor_type IN ('user','agent','system')", name: "events_actor_type_valid"
    end
    add_index :events, [:ticket_id, :created_at]
  end
end
