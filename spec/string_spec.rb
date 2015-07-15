require_relative 'test_helper'
require 'credit_card_validations/string'

describe 'String ext' do

  let(:mastercard) { CreditCardValidations::Factory.random(:mastercard) }
  let(:visa) { CreditCardValidations::Factory.random(:visa) }
  let(:invalid) { INVALID_NUMBERS.sample }

  it 'should allow detect brand for mastercard' do
    mastercard.credit_card_brand.must_equal :mastercard
    mastercard.credit_card_brand_name.must_equal 'MasterCard'
    mastercard.valid_credit_card_brand?(:mastercard).must_equal true
    mastercard.valid_credit_card_brand?('MasterCard').must_equal true
    mastercard.valid_credit_card_brand?(:visa, :amex).must_equal false
  end

  it 'should allow detect brand for visa' do
    visa.credit_card_brand.must_equal :visa
    visa.credit_card_brand_name.must_equal 'Visa'
    visa.valid_credit_card_brand?(:mastercard).must_equal false
    visa.valid_credit_card_brand?(:visa, :amex).must_equal true
  end

  it 'should not allow detect brand for invalid card' do
    invalid.credit_card_brand.must_be_nil
    invalid.credit_card_brand_name.must_be_nil
    invalid.valid_credit_card_brand?(:mastercard).must_equal false
    invalid.valid_credit_card_brand?(:visa, :amex).must_equal false
  end

end