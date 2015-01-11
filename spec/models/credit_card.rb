class CreditCard
  attr_accessor :number
  include ActiveModel::Validations
  validates :number, credit_card_number: {brands: [:amex, :maestro]}
end