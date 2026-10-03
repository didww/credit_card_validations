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
    # 0.074**100 -- it only happens for a brand detection can never return, and
    # random_card then answers with the brand it does return.
    MAX_DETECTION_RETRIES = 100

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
      # The CVV is sized from the brand the PAN *detects* as, and the PAN is
      # redrawn until that is the brand asked for. Only a brand registered
      # through add_brand can shadow the request on every draw; the card is
      # then sized for and reported as the brand detection does return.
      #
      # With no argument, draws a brand that declares a :code. The rest cannot
      # produce a card that answers true to #valid?, so including them would
      # make the no-arg call raise for 42% of invocations once every plugin is
      # required.
      #
      # Raises for a brand without :options[:code] (most plugin brands):
      # Detector.valid_cvv? raises on those, so no verification value we could
      # pick would give back a card that answers true to #valid?.
      def random_card(brand = nil)
        if brand.nil?
          # Only brands that declare a CVV size can produce a card that answers
          # true to #valid?, so a blind sample over every brand would raise for
          # 42% of calls once all plugins are required.
          brand = Detector.brands.keys.select { |key| cvv_size(key) }.sample
          raise Error.new('no registered brand declares a :code size') if brand.nil?
        end

        raise Error.new("brand #{brand.inspect} has no :code option") if cvv_size(brand).nil?

        # Card checks the CVV against the brand *detected* from the PAN, and
        # detection answers with the longest matching prefix -- another brand can
        # outrank the one we were asked for ('54...' at 16 digits is both
        # :mastercard and :diners_us). Redraw until detection agrees, so the CVV
        # is sized by the brand Card will actually enforce.
        number = random_number(brand)
        tries = 0
        while (detected = Detector.new(number).brand) != brand
          break if (tries += 1) > MAX_DETECTION_RETRIES
          number = random_number(brand)
        end

        # Normally `detected` is `brand` -- that is what the loop waits for.
        # But a brand registered through add_brand can tie with this one on
        # every prefix and win every tie, putting the requested brand out of
        # detection's reach. Answer with what detection does report rather than
        # giving up: a valid card with an honest #brand beats no card at all.
        size = cvv_size(detected)
        if size.nil?
          raise Error.new("every number generated for #{brand.inspect} detects as " \
                          "#{detected.inspect}, which has no :code option")
        end

        # Somewhere in the next five years, so a batch of generated cards does
        # not all carry the same expiry. 60 buckets collide constantly -- this
        # varies the date, it does not make it unique. One month is the minimum:
        # a card is live through the last day of its stated month, and starting
        # at zero would put some cards in the current month, which reads as
        # "about to expire" in fixtures.
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

      # Always computes the check digit, including for brands that declare
      # skip_luhn. That flag says detection *tolerates* a missing check digit,
      # not that real cards lack one -- all 55 UnionPay PANs in
      # spec/fixtures/valid_cards.yml carry a valid one. A computed digit
      # satisfies both the lenient and the strict reading, so it is the only
      # choice that keeps generated PANs usable against a second validator.
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