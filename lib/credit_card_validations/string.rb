# String extension for brand detecting and number validation
#
#    require 'credit_card_validations/string'
#    '5274 5763 9425 9961'.credit_card_brand
#    '5274 5763 9425 9961'.credit_card_brand_name
#    '5274 5763 9425 9961'.valid_credit_card_brand?(:mastercard, :visa)
#    '5274 5763 9425 9961'.valid_credit_card_brand?(:amex)
#
class String
  def credit_card_brand
    CreditCardValidations::Detector.new(self).brand
  end

  def valid_credit_card_brand?(*brands)
    CreditCardValidations::Detector.new(self).valid?(*brands)
  end

  def credit_card_brand_name
    CreditCardValidations::Detector.new(self).brand_name
  end

end  