
class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :account, null: false, foreign_key: true
      t.references :proposal, null: false, foreign_key: true, index: { unique: true } # one decision per proposal
      t.references :user, null: false, foreign_key: true
      t.string :decision, null: false
      t.integer :final_amount_cents
      t.text :rejection_reason
      t.datetime :reviewed_at, null: false
      t.timestamps

      t.check_constraint "decision IN ('approved','rejected')", name: "reviews_decision_valid"
      t.check_constraint "decision <> 'rejected' OR rejection_reason IS NOT NULL", name: "reviews_rejection_needs_reason"
    end
  end
end
