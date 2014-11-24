#
#
#
class String
  def credit_card_brand
    CreditCardValidations::Detector.new(self).brand
  end

  def valid_credit_card_brand?(*brands)
    CreditCardValidations::Detector.new(self).valid?(*brands)
  end
end  