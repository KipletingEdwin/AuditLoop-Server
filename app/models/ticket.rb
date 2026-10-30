class Ticket < ApplicationRecord
  belongs_to :account
  belongs_to :customer
end
