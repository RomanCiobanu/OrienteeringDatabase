class Category < ApplicationRecord
  has_many :runners
  has_many :results
end
