require_relative 'test_helper'

describe "ActiveModel Validator" do

  let(:model) { CreditCard.new }

  describe "Any Brand" do
    it "should be alid for all prepared valid numbers" do
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


  describe "Except Amex and Maestro brand" do
    it "should reject all other valid numbers" do
      VALID_NUMBERS.except(:amex, :maestro) do |_, numbers|
        card = model
        card.number = numbers.first
        card.valid?.must_equal false
      end
    end

    it "should accept using except options" do
      VALID_NUMBERS.except(:amex, :maestro) do |_, numbers|
        card = model
        card.number3 = numbers.first
        card.valid?.must_equal true
      end
    end

  end

  describe "Only Amex and Mestro brands" do


    it "should accept amex and maestro brand if valid" do
      VALID_NUMBERS.slice(:amex, :maestro) do |_, numbers|
        card = model
        card.number = numbers.first
        card.number2 = numbers.first
        card.valid?.must_equal true
      end
    end


  end
end
