# == ActiveModel CreditCardCvvValidator
#
# Validates a card verification value (CVV / CVC / CID) against either a
# brand passed explicitly, or a brand derived from another attribute.
#
#   class Payment
#     include ActiveModel::Validations
#     attr_accessor :card_number, :cvv
#
#     validates :cvv, credit_card_cvv: { brand_from: :card_number }
#   end
#
#   class Payment
#     validates :cvv, credit_card_cvv: { brand: :amex }
#   end
#
module ActiveModel
  module Validations
    class CreditCardCvvValidator < EachValidator
      def validate_each(record, attribute, value)
        brand = resolve_brand(record)
        return if brand && CreditCardValidations::Detector.valid_cvv?(value, brand)
        record.errors.add(attribute, options[:message] || :invalid)
      end

      private

      def resolve_brand(record)
        return options[:brand] if options[:brand]
        pan = record.public_send(options[:brand_from]).to_s if options[:brand_from]
        CreditCardValidations::Detector.new(pan).brand if pan
      end
    end
  end
end
