class AnyCreditCard
  attr_accessor :number
  include ActiveModel::Validations
  validates :number, presence: true, credit_card_number: true
end

