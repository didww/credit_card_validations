# == CreditCardValidations Luhn
# simple class to validate Luhn numbers.
#
#   Luhn.valid? 4111111111111111
#
module CreditCardValidations
  class Luhn
    def self.valid?(number)
      s1 = s2 = 0
      number.to_s.reverse.chars.each_slice(2) do |odd, even|
        s1 += odd.to_i

        double = even.to_i * 2
        double -= 9 if double >= 10
        s2 += double
      end
      (s1 + s2) % 10 == 0
    end
  end
end  
  
  