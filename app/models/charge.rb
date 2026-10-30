class Charge < ApplicationRecord
  belongs_to :account
  belongs_to :customer
  belongs_to :subscription
end
