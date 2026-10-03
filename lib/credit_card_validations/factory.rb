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
    # Redraws allowed while waiting for detection to agree with the requested
    # brand. The worst self-detection rate measured with all 25 plugins loaded
    # is :mastercard at 92.6%, so exhausting 100 draws has probability
    # 0.074**100 -- it only happens for a brand detection can never return.
    MAX_DETECTION_RETRIES = 100

    class << self
      def random_number(brand = nil)
        brand = Detector.brands.keys.sample if brand.nil?
        spec = Detector.brands[brand]
        if spec.nil?
          raise Error.new('Unsupported brand')
        end
        # skip_luhn is declared on the brand, not on the individual rule.
        generate(spec[:rules].sample, spec.fetch(:options, {})[:skip_luhn])
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
      # Raises for a brand without :options[:code] (most plugin brands):
      # Detector.valid_cvv? raises on those, so no verification value we could
      # pick would give back a card that answers true to #valid?.
      def random_card(brand = nil)
        if brand.nil?
          # Only brands that declare a CVV size can produce a card that answers
          # true to #valid?, so a blind sample over every brand would raise for
          # 42% of calls once all plugins are required.
          brand = Detector.brands.select { |_, b| b.dig(:options, :code, :size) }.keys.sample
          raise Error.new('no registered brand declares a :code size') if brand.nil?
        end

        number = random_number(brand)
        size = Detector.brands.dig(brand, :options, :code, :size)
        raise Error.new("brand #{brand.inspect} has no :code option") if size.nil?

        # Card checks the CVV against the brand *detected* from the PAN, and
        # detection answers with the longest matching prefix -- a plugin can
        # outrank the brand we were asked for ('54...' at 16 digits is both
        # :mastercard and :diners_us). Redraw until detection agrees, so the
        # size above is the one Card will actually enforce.
        tries = 0
        until Detector.new(number).brand == brand
          if (tries += 1) > MAX_DETECTION_RETRIES
            raise Error.new("gave up generating a number that detects as #{brand.inspect}")
          end
          number = random_number(brand)
        end

        # Somewhere in the next five years, so two generated cards do not share
        # an expiry. One month is the minimum: a card is live through the last
        # day of its stated month, and starting at zero would put some cards in
        # the current month, which reads as "about to expire" in fixtures.
        expires_on = Date.today.next_month(rand(1..60))
        Card.new(number: number,
                 month: expires_on.month,
                 year: expires_on.year,
                 verification_value: Array.new(size) { rand(10) }.join)
      end

      def generate(rule, skip_luhn = false)
        number(rule[:prefixes].sample, rule[:length].sample, skip_luhn)
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