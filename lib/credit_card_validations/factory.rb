# == CreditCardValidations Factory
# Generates cards and card numbers that pass validation
#
# #random_number
#   CreditCardValidations::Factory.random_number
# #or particular brand
#   CreditCardValidations::Factory.random_number(:maestro) # "6010430241237266856"
#
# #random_card
#   CreditCardValidations::Factory.random_card(:amex) # #<CreditCardValidations::Card>
#
#
module CreditCardValidations
  class Factory
    class << self
      def random_number(brand = nil)
        brand = Detector.brands.keys.sample if brand.nil?
        spec = Detector.brands[brand]
        if spec.nil?
          raise Error.new('Unsupported brand')
        end
        generate(spec[:rules].sample)
      end

      # Released as the only generator up to v9; keep it working.
      alias_method :random, :random_number

      # Whole test card, not just a PAN: valid number, expiration 1-60 months out
      # and a verification value of the size the brand declares.
      #
      #   card = CreditCardValidations::Factory.random_card(:amex)
      #   card.valid?             # => true
      #   card.verification_value # => "8812"
      #
      # Needs the brand to declare a :code size and raises
      # CreditCardValidations::Error otherwise.
      def random_card(brand = nil)
        if brand.nil?
          brand = Detector.brands.keys.select { |key| cvv_size(key) }.sample
          raise Error.new('no registered brand declares a :code size') if brand.nil?
        end

        # Saying a brand has no :code option would imply it is registered.
        raise Error.new('Unsupported brand') if Detector.brands[brand].nil?
        raise Error.new("brand #{brand.inspect} has no :code option") if cvv_size(brand).nil?

        # Card checks the CVV against the brand *detected* from the PAN, not the
        # one we asked for, so the size has to come from there. Which brand wins
        # an overlap is Detector's business, not the factory's.
        number = random_number(brand)
        detected = Detector.new(number).brand
        size = cvv_size(detected)
        if size.nil?
          raise Error.new("the number generated for #{brand.inspect} detects as " \
                          "#{detected.inspect}, which has no :code option")
        end

        # One month out at least: a card is live through the last day of its
        # stated month, so zero would mean "about to expire".
        expires_on = Date.today.next_month(rand(1..60))
        Card.new(number: number,
                 month: expires_on.month,
                 year: expires_on.year,
                 verification_value: Array.new(size) { rand(10) }.join)
      end

      def cvv_size(brand)
        Detector.brands.dig(brand, :options, :code, :size)
      end

      def generate(rule)
        number(rule[:prefixes].sample, rule[:length].sample)
      end

      # Computes the check digit for skip_luhn brands too. That flag says
      # detection *tolerates* a missing check digit, not that real cards lack
      # one -- all 55 UnionPay PANs in the fixtures carry a valid one.
      def number(prefix, length)
        number = prefix.dup
        1.upto(length - (prefix.length + 1)) do
          number << "#{rand(10)}"
        end
        number + last_digit(number).to_s
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