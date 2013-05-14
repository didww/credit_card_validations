module ActiveModel
  module Validations
    class CreditCardNumberValidator < EachValidator

      def validate_each(record, attribute, value)
        brands = options.fetch(:brands) 
        record.errors.add(attribute) unless credit_card_valid?(value, brands == :any ? [] : Array.wrap(brands) )
      end

      def credit_card_valid?(number, brands = [])
        CreditCardValidations::Detector.new(number).valid?(*brands)
      end
    end
  end
end

