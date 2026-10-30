
class CreateToolCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :tool_calls do |t|
      t.references :account, null: false, foreign_key: true
      t.references :agent_run, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :name, null: false
      t.jsonb :input, null: false, default: {}
      t.jsonb :output, null: false, default: {}
      t.timestamps
    end
    add_index :tool_calls, [:agent_run_id, :position], unique: true
  end
end
