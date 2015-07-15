require_relative 'test_helper'

describe 'ActiveModel Validator' do

  let(:model) { CreditCard.new }

  describe 'Proc support' do
    it 'should be valid if brands from proc valid' do
       card = model.dup
       card.card_type = 'Master Card'
       card.number6 =  CreditCardValidations::Factory.random(:visa)
       card.valid?.must_equal false
       card.number6 =  CreditCardValidations::Factory.random(:mastercard)
       card.valid?.must_equal true
    end
  end

  describe 'Any Brand' do
    it 'should be valid for all prepared valid numbers' do
      VALID_NUMBERS.each do |_, numbers|
        numbers.each do |number|
          card = model
          card.number4 = number
          card.number5 = number
          card.valid?.must_equal true
        end
      end
    end
  end

  describe 'Except Amex and Maestro brand' do
    it 'should reject all other valid numbers' do
      VALID_NUMBERS.except(:amex, :maestro).each do |_, numbers|
        card = model
        card.number = numbers.first
        card.valid?.must_equal false
        card.errors[:number].include?(card.errors.generate_message(:number, :invalid)).must_equal true
      end
    end

    it 'should accept using except options' do
      VALID_NUMBERS.except(:amex, :maestro).each do |_, numbers|
        card = model
        card.number3 = numbers.first
        card.valid?.must_equal true
      end
    end
  end

  describe 'Only Amex and Mestro brands' do
    it 'should accept amex and maestro brand if valid' do
      VALID_NUMBERS.slice(:amex, :maestro).each do |_, numbers|
        card = model
        card.number = numbers.first
        card.number2 = numbers.first
        card.valid?.must_equal true
      end
    end
  end

  describe 'Custom error message' do
    it 'should allow custom message' do
      card = model
      card.number7 =  'wrong'
      card.valid?.must_equal false
      card.errors[:number7].must_equal ['Custom message']
    end
  end

end
