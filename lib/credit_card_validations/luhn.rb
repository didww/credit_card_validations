# == CreditCardValidations Luhn
# Strict Luhn validator — accepts digit-only strings.
#
#   Luhn.valid?('4111111111111111')   # => true
#   Luhn.valid?('4111 1111 1111 1111') # => false (caller must strip formatting)
#   Luhn.valid?('')                    # => false
#   Luhn.valid?(nil)                   # => false
#
# Call sites that handle user input should strip formatting first; the
# bundled Detector does this before delegating here.
#
module CreditCardValidations
  class Luhn
    def self.valid?(number)
      return false if number.nil? || !number.match?(/\A\d+\z/)

      s1 = s2 = 0
      number.reverse.chars.each_slice(2) do |odd, even|
        s1 += odd.to_i
        double = even.to_i * 2
        double -= 9 if double >= 10
        s2 += double
      end
      (s1 + s2) % 10 == 0
    end
  end
end
