require_relative 'test_helper'

describe CreditCardValidations::Factory do

  it 'should generate random brand' do
    number = CreditCardValidations::Factory.random
    CreditCardValidations::Detector.new(number).valid?.must_equal true
  end

  CreditCardValidations::Detector.brands.keys.sort.each do |key|
    describe "#{key}" do
      it "should generate valid #{key}" do
        number = CreditCardValidations::Factory.random(key)
        CreditCardValidations::Detector.new(number).valid?(key).must_equal true
      end
    end
  end
end