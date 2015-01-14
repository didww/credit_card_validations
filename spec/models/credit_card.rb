class CreditCard
  attr_accessor :number,  :number4, :number5
  include ActiveModel::Validations
  validates :number, credit_card_number: {brands: [:amex, :maestro]} , allow_blank: true

  validates :number4, credit_card_number: {brands: :any}  , allow_blank: true
  validates :number5, credit_card_number: true , allow_blank: true
end