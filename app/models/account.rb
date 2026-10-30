
class Account < ApplicationRecord
  has_many :users
  has_many :customers
  has_many :subscriptions
  has_many :charges
  has_many :tickets
  has_many :events

  validates :name, presence: true
end