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
#  end
#
#  Proc can be used as well
#
#  class CreditCard
#     attr_accessor :number, :card_type
#     include ActiveModel::Validations
#     validates :number, credit_card_number: {brands: ->{|record|  Array(record.accepted_brands) }  }
#
#     def accepted_brands
#       if card_type == 'Maestro'
#         :maestro
#       elsif card_type == 'American Express'
#         :amex
#       else
#         :visa
#       end
#     end
#
#  end
#
#

module ActiveModel
  module Validations
    class CreditCardNumberValidator < EachValidator

      def validate_each(record, attribute, value)
        record.errors.add(attribute, options[:message] || :invalid) unless credit_card_valid?(value, extract_brands(record, options))
      end

      def credit_card_valid?(number, brands = [])
        CreditCardValidations::Detector.new(number).valid?(*brands)
      end

      protected

      def extract_brands(record, options)
        if options.has_key?(:brands)
          with_brands(record, options[:brands])
        elsif options.has_key?(:only)
          Array(options[:only])
        elsif options.has_key?(:except)
          Array(CreditCardValidations::Detector.brands.keys) - Array(options[:except])
        else
          []
        end

      end

      def with_brands(record, brands)
        if brands.is_a?(Proc)
          brands.call(record)
        elsif options[:brands] == :any
          []
        else
          Array(options[:brands])
        end
      end

    end
  end
end

