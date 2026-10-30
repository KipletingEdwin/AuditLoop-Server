
class Customer < ApplicationRecord
  include AccountScoped

  has_many :subscriptions
  has_many :charges
  has_many :tickets

  normalizes :email, with: ->(e) { e.strip.downcase }
  validates :external_id, :email, presence: true
end