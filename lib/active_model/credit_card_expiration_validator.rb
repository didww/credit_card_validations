# == ActiveModel CreditCardExpirationValidator
#
# Validates a card expiration date held in a single attribute as a parseable
# string (MM/YY, MM/YYYY, MMYY, ...).
#
#   class Payment
#     include ActiveModel::Validations
#     attr_accessor :expiration
#
#     validates :expiration, credit_card_expiration: true
#   end
#
# For forms with separate month + year fields, use the Expiration class
# directly in a plain validate block (see README).
#
module ActiveModel
  module Validations
    class CreditCardExpirationValidator < EachValidator
      def validate_each(record, attribute, value)
        expiration = CreditCardValidations::Expiration.parse(value)
        return if expiration && expiration.valid?
        record.errors.add(attribute, options[:message] || :invalid)
      end
    end
  end
end
