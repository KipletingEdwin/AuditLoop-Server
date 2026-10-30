class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :account, null: false, foreign_key: true
      t.references :ticket, null: false, foreign_key: true
      t.string :actor_type
      t.bigint :actor_id
      t.string :name
      t.jsonb :data

      t.timestamps
    end
  end
end
