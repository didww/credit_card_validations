# == ActiveModel Validations CreditCardNumberValidator
#  Can  be used in combination with the +validates+ method
#
#   Only Amex and Maestro
#
#   class CreditCard
#     attr_accessor :number
#     include ActiveModel::Validations
#     validates :number, credit_card_number: {only: [:amex, :maestro]}
#   end
#
#   All numbers are valid except Maestro
#
#  class CreditCard
#     attr_accessor :number
#     include ActiveModel::Validations
#     validates :number, credit_card_number: {except: [:maestro]}
#   end
#

module ActiveModel
  module Validations
    class CreditCardNumberValidator < EachValidator

      def validate_each(record, attribute, value)
        record.errors.add(attribute) unless credit_card_valid?(value, extract_brands(options))
      end

      def credit_card_valid?(number, brands = [])
        CreditCardValidations::Detector.new(number).valid?(*brands)
      end

      protected

      def extract_brands(options)
         if options.has_key?(:brands)
           options[:brands] == :any ? [] : Array(options[:brands])
         elsif options.has_key?(:only)
           Array(options[:only])
         elsif options.has_key?(:except)
           Array(CreditCardValidations::Detector.brands.keys) - Array(options[:except])
         else
           []
         end

      end

    end
  end
end

