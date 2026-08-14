class Brand < ApplicationRecord
  has_many :equipment, dependent: :destroy

  class << self
  end
end
