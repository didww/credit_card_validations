require_relative 'test_helper'
require 'credit_card_validations/string'

describe 'String ext' do

  let(:mastercard) { CreditCardValidations::Factory.random(:mastercard) }
  let(:visa) { CreditCardValidations::Factory.random(:visa) }
  let(:invalid) { INVALID_NUMBERS.sample }

  it 'should allow detect brand for mastercard' do
    expect(mastercard.credit_card_brand).must_equal :mastercard
    expect(mastercard.credit_card_brand_name).must_equal 'MasterCard'
    expect(mastercard.valid_credit_card_brand?(:mastercard)).must_equal true
    expect(mastercard.valid_credit_card_brand?('MasterCard')).must_equal true
    expect(mastercard.valid_credit_card_brand?(:visa, :amex)).must_equal false
  end

  it 'should allow detect brand for visa' do
    expect(visa.credit_card_brand).must_equal :visa
    expect(visa.credit_card_brand_name).must_equal 'Visa'
    expect(visa.valid_credit_card_brand?(:mastercard)).must_equal false
    expect(visa.valid_credit_card_brand?(:visa, :amex)).must_equal true
  end

  it 'should not allow detect brand for invalid card' do
    expect(invalid.credit_card_brand).must_be_nil
    expect(invalid.credit_card_brand_name).must_be_nil
    expect(invalid.valid_credit_card_brand?(:mastercard)).must_equal false
    expect(invalid.valid_credit_card_brand?(:visa, :amex)).must_equal false
  end

end