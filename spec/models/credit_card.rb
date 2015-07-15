class CreditCard
  attr_accessor :number, :number2, :number3, :number4, :number5, :number6, :number7, :card_type
  include ActiveModel::Validations
  validates :number, credit_card_number: { brands: [:amex, :maestro] }, allow_blank: true
  validates :number2, credit_card_number: { only: [:amex, :maestro] }, allow_blank: true
  validates :number3, credit_card_number: { except: [:amex, :maestro] }, allow_blank: true
  validates :number4, credit_card_number: { brands: :any }, allow_blank: true
  validates :number5, credit_card_number: true, allow_blank: true
  validates :number6, credit_card_number: { brands: ->(record) { record.supported_brand } }, allow_blank: true
  validates :number7, credit_card_number: { message: 'Custom message' }, allow_blank: true

  def supported_brand
    {
      'Master Card' => :mastercard,
      'Visa' => :visa
    }[self.card_type]
  end

end