
class Account < ApplicationRecord
  has_many :users
  has_many :customers
  has_many :subscriptions
  has_many :charges
  has_many :tickets
  has_many :events
  has_many :agent_runs
  has_many :proposals
  has_many :refunds
  has_many :reviews

  validates :name, presence: true
end