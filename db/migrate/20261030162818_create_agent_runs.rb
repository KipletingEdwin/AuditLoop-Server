
class CreateAgentRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_runs do |t|
      t.references :account, null: false, foreign_key: true
      t.references :ticket, null: false, foreign_key: true
      t.string :llm_model, null: false
      t.string :prompt_version, null: false
      t.string :status, null: false, default: "running"
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.text :error
      t.timestamps

      t.check_constraint "status IN ('running','completed','failed')", name: "agent_runs_status_valid"
    end
  end
end
