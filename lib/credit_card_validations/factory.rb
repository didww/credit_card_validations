# == CreditCardValidations Factory
# Generates card number that passes validation
#
# #random
#   CreditCardValidations::Factory.random
# #or particular brand
#   CreditCardValidations::Factory.random(:maestro) # "6010430241237266856"
#
#
#
module CreditCardValidations
  class Factory
    class << self
      def random(brand = nil)
        brand = Detector.brands.keys.sample if brand.nil?
        if Detector.brands[brand].nil?
          raise Error.new('Unsupported brand')
        end
        generate(Detector.brands[brand][:rules].sample)
      end

      def generate(rule)
        number(rule[:prefixes].sample, rule[:length].sample, rule.fetch(:options, {})[:skip_luhn])
      end

      def number(prefix, length, skip_luhn = false)
        number = prefix.dup
        1.upto(length - (prefix.length + 1)) do
          number << "#{rand(9)}"
        end
        #if skip luhn
        if skip_luhn
          number += "#{rand(9)}"
        else
          number += last_digit(number).to_s
        end
        number
      end

      #extracted from darkcoding-credit-card

      def last_digit(number)
        # Calculate sum
        sum, pos = 0, 0
        length = number.length + 1

        reversed_number = number.reverse
        while pos < length do
          odd = reversed_number[pos].to_i * 2
          odd -= 9 if odd > 9

          sum += odd

          sum += reversed_number[pos + 1].to_i if pos != (length - 2)

          pos += 2
        end

        (((sum / 10).floor + 1) * 10 - sum) % 10
      end

    end
  end
end