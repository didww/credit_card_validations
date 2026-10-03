require_relative 'test_helper'

describe CreditCardValidations::Factory do

  it 'should generate random brand' do
    number = CreditCardValidations::Factory.random
    expect(CreditCardValidations::Detector.new(number).valid?).must_equal true
  end

  CreditCardValidations::Detector.brands.keys.sort.each do |key|
    describe "#{key}" do
      it "should generate valid #{key}" do
        number = CreditCardValidations::Factory.random(key)
        expect(CreditCardValidations::Detector.new(number).valid?(key)).must_equal true
      end
    end
  end

  describe '.random_number' do
    it 'generates a valid number for the given brand' do
      number = CreditCardValidations::Factory.random_number(:visa)
      expect(CreditCardValidations::Detector.new(number).valid?(:visa)).must_equal true
    end

    it 'generates a valid number for a random brand when none is given' do
      number = CreditCardValidations::Factory.random_number
      expect(CreditCardValidations::Detector.new(number).valid?).must_equal true
    end

    it 'leaves the check digit random for a brand that declares skip_luhn' do
      numbers = Array.new(500) { CreditCardValidations::Factory.random_number(:unionpay) }
      luhn_valid = numbers.count { |number| CreditCardValidations::Luhn.valid?(number) }

      # :unionpay declares skip_luhn, so the last digit is drawn, not computed,
      # and lands on the Luhn-valid value about 1 in 10 times. P(more than 200
      # of 500) is bounded by exp(-500 * D(0.4||0.1)) = 2e-68. The current code
      # computes the check digit for every brand, giving 500 of 500.
      expect(luhn_valid).must_be :<, 200
    end

    it 'keeps .random as an alias of the very same method' do
      factory = CreditCardValidations::Factory
      expect(factory.method(:random)).must_equal factory.method(:random_number)
      expect(factory.method(:random).original_name).must_equal :random_number
    end

    it 'still accepts the legacy .random name' do
      number = CreditCardValidations::Factory.random(:amex)
      expect(CreditCardValidations::Detector.new(number).valid?(:amex)).must_equal true
    end
  end

  describe '.number' do
    it 'draws every generated digit from the whole 0-9 range' do
      body = Array.new(200) { CreditCardValidations::Factory.number('4', 19)[1..-2] }.join
      drawn_check_digits = Array.new(500) { CreditCardValidations::Factory.number('62', 16, true)[-1] }

      # 200 numbers x 17 filler digits = 3400 draws, so 340 nines are expected.
      # P(X <= 100) for X ~ Binomial(3400, 0.1) is bounded by
      # exp(-3400 * D(0.0294||0.1)) = 2e-55.
      expect(body.length).must_equal 3400
      expect(body.count('9')).must_be :>, 100

      # 500 drawn check digits, 50 nines expected. P(X <= 10) for
      # X ~ Binomial(500, 0.1) is bounded by exp(-500 * D(0.02||0.1)) = 8e-12.
      expect(drawn_check_digits.count('9')).must_be :>, 10
    end
  end

  describe '.random_card' do
    plugin_brands = Dir[File.expand_path('../lib/credit_card_validations/plugins/*.rb', __dir__)]
                      .map { |path| File.basename(path, '.rb').to_sym }.sort

    # Loading a plugin defines a predicate on Detector that reload! alone does
    # not undo — only delete_brand does. Wipe every brand, then reload.
    after do
      CreditCardValidations::Detector.brands.keys.each do |key|
        CreditCardValidations::Detector.delete_brand(key)
      end
      CreditCardValidations.reload!
    end

    (CreditCardValidations::Detector.brands.keys.sort + plugin_brands).each do |brand|
      it "builds a valid card for #{brand}" do
        load "credit_card_validations/plugins/#{brand}.rb" if plugin_brands.include?(brand)
        size = CreditCardValidations::Detector.brands.dig(brand, :options, :code, :size)

        if size.nil?
          # Detector.valid_cvv? raises for a brand with no :code, so no CVV
          # could make such a card valid — random_card must say so up front.
          error = expect { CreditCardValidations::Factory.random_card(brand) }
                    .must_raise CreditCardValidations::Error
          expect(error.message).must_match(/no :code option/)
        else
          card = CreditCardValidations::Factory.random_card(brand)
          expect(card).must_be_instance_of CreditCardValidations::Card
          expect(card.brand).must_equal brand
          expect(card.verification_value.length).must_equal size
          expect(card.expired?).must_equal false
          expect(card.valid?).must_equal true
        end
      end
    end

    it 'picks a random brand when none is given' do
      card = CreditCardValidations::Factory.random_card
      expect(card.valid?).must_equal true
    end

    it 'returns the requested brand even when a plugin shadows one of its prefixes' do
      %w[diners_us elo uatp girocard].each do |plugin|
        load "credit_card_validations/plugins/#{plugin}.rb"
      end

      # :mastercard draws from 28 prefixes; 2 of them ('54', '55') are also the
      # whole of :diners_us, which matches the same 16-digit length. The tie on
      # matched prefix length goes to the plugin, so the PAN detects as
      # :diners_us -- a brand with no :code -- and Card#valid? raises while
      # checking a CVV sized from the brand that was *asked* for.
      # Chance of 300 draws never touching '54'/'55': (26/28)**300 = 2.2e-10.
      300.times do
        card = CreditCardValidations::Factory.random_card(:mastercard)
        expect(card.brand).must_equal :mastercard
        expect(card.valid?).must_equal true
      end
    end

    it 'only picks a brand that can produce a valid card when none is given' do
      plugin_brands.each { |plugin| load "credit_card_validations/plugins/#{plugin}.rb" }

      # 14 of the 33 brands then registered declare no :code, so a uniform draw
      # over every brand raises for 42% of calls. The chance of 200 draws
      # getting away without a single raise is 0.576**200 = 1e-48.
      200.times do
        card = CreditCardValidations::Factory.random_card
        expect(card.valid?).must_equal true
      end
    end

    it 'raises when not a single registered brand declares a :code size' do
      CreditCardValidations::Detector.brands.keys.each do |key|
        CreditCardValidations::Detector.delete_brand(key)
      end
      CreditCardValidations.add_brand(:codeless, { length: 16, prefixes: '99' })

      error = expect { CreditCardValidations::Factory.random_card }
                .must_raise CreditCardValidations::Error
      expect(error.message).must_match(/no registered brand/)
    end

    it 'raises on an unsupported brand' do
      expect { CreditCardValidations::Factory.random_card(:nope) }
        .must_raise CreditCardValidations::Error
    end

    it 'varies the expiration instead of stamping every card with the same date' do
      dates = Array.new(50) do
        card = CreditCardValidations::Factory.random_card(:visa)
        [card.month, card.year]
      end

      expect(dates.uniq.size).must_be :>, 1
    end

    it 'keeps every expiration in the future' do
      today = Date.today

      Array.new(50) { CreditCardValidations::Factory.random_card(:visa) }.each do |card|
        expect(card.expired?).must_equal false
        expect(Date.new(card.year, card.month, 1)).must_be :>=, Date.new(today.year, today.month, 1)
      end
    end
  end
end