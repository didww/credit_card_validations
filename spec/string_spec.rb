require_relative 'test_helper'
require 'credit_card_validations/string'

describe "String ext" do

  let(:mastercard) {
    CreditCardValidations::Factory.random(:mastercard)
  }

  it "should allow detect brand" do

    mastercard.credit_card_brand.must_equal :mastercard
    mastercard.valid_credit_card_brand?(:mastercard).must_equal true
    mastercard.valid_credit_card_brand?(:visa, :amex).must_equal false
  end

end