class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.references :account, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :from_email
      t.string :subject
      t.text :body
      t.datetime :received_at
      t.string :state

      t.timestamps
    end
  end
end
