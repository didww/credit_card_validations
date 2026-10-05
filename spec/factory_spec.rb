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

    it 'computes the check digit even for a brand that declares skip_luhn' do
      number = CreditCardValidations::Factory.random_number(:unionpay)

      expect(number[-1]).must_equal CreditCardValidations::Factory.last_digit(number[0..-2]).to_s
      expect(CreditCardValidations::Luhn.valid?(number)).must_equal true
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
      body = Array.new(20) { CreditCardValidations::Factory.number('4', 19)[1..-2] }.join
      cvvs = Array.new(100) { CreditCardValidations::Factory.random_card(:visa).verification_value }.join

      digits = (0..9).map(&:to_s)
      expect(body.length).must_equal 340
      expect(body.chars.uniq.sort).must_equal digits

      expect(cvvs.length).must_equal 300
      expect(cvvs.chars.uniq.sort).must_equal digits
    end
  end

  describe '.random_card' do

    # Loading a plugin defines a predicate on Detector that reload! alone does
    # not undo — only delete_brand does. Wipe every brand, then reload.
    after do
      CreditCardValidations::Detector.brands.keys.each do |key|
        CreditCardValidations::Detector.delete_brand(key)
      end
      CreditCardValidations.reload!
    end

    (CreditCardValidations::Detector.brands.keys.sort + PLUGIN_BRANDS).each do |brand|
      it "builds a valid card for #{brand}" do
        load_plugin(brand)
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

    it 'draws the number from the requested brand, whichever brand detects it' do
      CreditCardValidations.add_brand(:visa_debit, { length: [13, 16, 19], prefixes: '4' },
                                      { code: { name: 'CVV', size: 3 } })
      detected = CreditCardValidations::Detector.new('4111111111111111').brand

      # The number is a valid number of the brand asked for -- that is the
      # guarantee; which brand detection names is Detector's business.
      card = CreditCardValidations::Factory.random_card(:visa)
      expect(card.brand).must_equal detected
      expect(card.valid?).must_equal true
      expect(CreditCardValidations::Detector.new(card.number).valid?(:visa)).must_equal true
    end

    it 'only picks a brand that can produce a valid card when none is given' do
      CreditCardValidations::Detector.brands.keys.each do |key|
        CreditCardValidations::Detector.delete_brand(key)
      end
      CreditCardValidations.add_brand(:codeless, { length: 16, prefixes: '98' })
      CreditCardValidations.add_brand(:coded, { length: 16, prefixes: '99' },
                                      { code: { name: 'CVV', size: 3 } })

      card = CreditCardValidations::Factory.random_card

      expect(card.brand).must_equal :coded
      expect(card.valid?).must_equal true
    end

    it 'raises when the drawn number detects as a brand with no :code' do
      # Only reachable where ranges overlap, and then rarely, so the number is
      # stubbed rather than drawn.
      load_plugin(:uatp)
      CreditCardValidations::Factory.stubs(:random_number).returns('100000000000006')

      error = expect { CreditCardValidations::Factory.random_card(:jcb) }
                .must_raise CreditCardValidations::Error
      expect(error.message).must_match(/no :code option/)
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

    it 'raises on an unsupported brand, the same way random_number does' do
      # Saying a brand has no :code option implies it is registered. These two
      # cases are different and the messages have to tell them apart.
      unknown = expect { CreditCardValidations::Factory.random_card(:nope) }
                  .must_raise CreditCardValidations::Error
      expect(unknown.message).must_equal 'Unsupported brand'

      load_plugin(:uatp)
      codeless = expect { CreditCardValidations::Factory.random_card(:uatp) }
                   .must_raise CreditCardValidations::Error
      expect(codeless.message).must_match(/:uatp has no :code option/)
    end

    it 'varies the expiration instead of stamping every card with one date' do
      dates = Array.new(50) do
        card = CreditCardValidations::Factory.random_card(:visa)
        [card.month, card.year]
      end

      expect(dates.uniq.size).must_be :>, 1
    end

    it 'keeps every expiration at least one month out' do
      this_month = Date.today.year * 12 + Date.today.month
      offsets = Array.new(1000) do
        card = CreditCardValidations::Factory.random_card(:visa)
        card.year * 12 + card.month - this_month
      end

      expect(offsets.min).must_be :>=, 1
    end
  end
end
