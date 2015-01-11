require_relative 'test_helper'

class ActiveModelValidationTest < CreditCardValidations::Specs
  describe "ActiveModel Validator" do

    describe "Any brand" do
      let(:model) { AnyCreditCard.new }
      it "should accept any brand if valid" do
        valid_numbers.each do |_, numbers|
          card = model
          card.number = numbers.first
          card.valid?.must_equal true
        end
      end

      it "should reject invalid numbers" do
        invalid_numbers.each do |number|
          card = model
          card.number = number
          card.valid?.must_equal false
        end
      end

    end

    describe "Only Amex and Mestro brands" do
      let(:model) { CreditCard.new }

      it "should accept amex and maestro brand if valid" do
        valid_numbers.slice(:amex, :maestro) do |_, numbers|
          card = model
          card.number = numbers.first
          card.valid?.must_equal true
        end
      end

      it "should reject all other valid numbers" do
        valid_numbers.except(:amex, :maestro) do |_, numbers|
          card = model
          card.number = numbers.first
          card.valid?.must_equal false
        end

      end

    end
  end

end