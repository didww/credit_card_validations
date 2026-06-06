require_relative 'test_helper'

describe CreditCardValidations do


  before do
    CreditCardValidations.reload!
  end


  describe 'configure' do

    let(:number) { '6111111180456137' }

    before do
      expect(card_detector.valid?(:discover)).must_equal false
      CreditCardValidations.configure do |config|
        config.source = OVERRIDED_BRANDS_FILE
      end
    end

    let(:card_detector) {
      detector(number)
    }

    it 'should generate overrided discover' do
      discover = CreditCardValidations::Factory.random(:discover)
      expect(detector(discover).valid?('DiscoverBrand')).must_equal true
    end

    it 'should detect patched discover' do
      expect(card_detector.valid?(:discover)).must_equal true
      expect(card_detector.valid?(:visa)).must_equal false
    end

    after do
      CreditCardValidations.reset
      CreditCardValidations.reload!
    end

  end

  describe 'safe YAML loading' do
    it 'rejects a brand source containing arbitrary Ruby objects' do
      require 'tempfile'
      Tempfile.create(['unsafe', '.yaml']) do |f|
        f.write("--- !ruby/object:Object {}\n")
        f.flush
        expect(-> {
          CreditCardValidations.configure { |c| c.source = f.path }
        }).must_raise Psych::DisallowedClass
      end
    ensure
      CreditCardValidations.reset
      CreditCardValidations.reload!
    end
  end

  describe 'MMI' do
    it 'should detect issuer category' do
      d = detector(VALID_NUMBERS[:visa].first)
      expect(d.issuer_category).must_equal CreditCardValidations::Mmi::ISSUER_CATEGORIES[d.number[0]]
    end
  end

  describe 'Luhn#valid?' do
    let(:card_detector) {
      detector(VALID_NUMBERS[:unionpay].first)
    }
    it 'should call Luhn.valid? once' do
      CreditCardValidations::Luhn.expects(:valid?).with(card_detector.number).once
      expect(card_detector.valid?(:visa, :unionpay)).must_equal true
    end

    it 'should call Luhn.valid? twice' do
      CreditCardValidations::Luhn.expects(:valid?).with(card_detector.number).twice
      expect(card_detector.valid?(:visa, :mastercard)).must_equal false
    end

    it 'should not call Luhn.valid?' do
      CreditCardValidations::Luhn.expects(:valid?).never
      expect(card_detector.valid?(:unionpay)).must_equal true
    end

    describe 'strict input contract' do
      let(:valid_pan) { VALID_NUMBERS[:visa].first.tr(' -', '') }

      it 'rejects formatted PAN (caller must strip)' do
        expect(CreditCardValidations::Luhn.valid?("4111 1111 1111 1111")).must_equal false
        expect(CreditCardValidations::Luhn.valid?("4111-1111-1111-1111")).must_equal false
        expect(CreditCardValidations::Luhn.valid?("#{valid_pan}\n")).must_equal false
      end

      it 'rejects non-digit garbage' do
        expect(CreditCardValidations::Luhn.valid?("4111abcd11111111")).must_equal false
      end

      it 'rejects nil and empty string' do
        expect(CreditCardValidations::Luhn.valid?(nil)).must_equal false
        expect(CreditCardValidations::Luhn.valid?('')).must_equal false
      end

      it 'accepts a clean digit string' do
        expect(CreditCardValidations::Luhn.valid?(valid_pan)).must_equal true
      end
    end

    describe 'Detector strips formatting before delegating' do
      it 'accepts spaces, dashes, and whitespace in Detector input' do
        formatted  = '4111 1111 1111 1111'
        with_dashes = '4111-1111-1111-1111'
        from_csv    = "4111111111111111\n"
        expect(CreditCardValidations::Detector.new(formatted).valid?).must_equal true
        expect(CreditCardValidations::Detector.new(with_dashes).valid?).must_equal true
        expect(CreditCardValidations::Detector.new(from_csv).valid?).must_equal true
      end
    end
  end


  it 'should check luhn' do
    VALID_NUMBERS.each do |brand, card_numbers|
      load_legacy_plugin(brand)
      if has_luhn_check_rule?(brand)
        card_numbers.each do |number|
          expect(luhn_valid?(detector(number).number)).must_equal true
        end
      end
    end
  end

  it 'should check valid brand' do
    VALID_NUMBERS.each do |brand, card_numbers|
      load_legacy_plugin(brand)
      card_numbers.each do |card_number|
        expect(detector(card_number).send("#{brand}?")).must_equal true
        expect(detector(card_number).brand).must_equal brand
      end
    end
  end

  it 'should check if card invalid' do
    VALID_NUMBERS.keys.each { |brand| load_legacy_plugin(brand) }
    INVALID_NUMBERS.each do |card_number|
      expect(detector(card_number).valid?).must_equal false
      expect(detector(card_number).brand).must_be_nil
      VALID_NUMBERS.keys.each do |brand|
        expect(detector(card_number).send("#{brand}?")).must_equal false
      end
    end
  end

  it 'should detect by full brand name' do
    amex = CreditCardValidations::Factory.random(:amex)
    expect(detector(amex).valid?('American Express')).must_equal true
    visa = CreditCardValidations::Factory.random(:visa)
    expect(detector(visa).valid?('American Express')).must_equal false
  end

  describe 'PAN display helpers' do
    let(:visa) { detector('4111 1111 1111 1111') }
    let(:amex) { detector('3782 822463 10005') }

    describe '#last4' do
      it 'returns the last four digits of the PAN' do
        expect(visa.last4).must_equal '1111'
        expect(amex.last4).must_equal '0005'
      end

      it 'returns nil for a PAN shorter than 4 digits' do
        expect(detector('12').last4).must_be_nil
        expect(detector('').last4).must_be_nil
      end
    end

    describe '#masked' do
      it 'replaces every digit except the last 4 with the mask char' do
        expect(visa.masked).must_equal '************1111'
        expect(amex.masked).must_equal '***********0005'
      end

      it 'accepts a custom mask char' do
        expect(visa.masked('#')).must_equal '############1111'
      end

      it 'does not raise and returns the input when PAN is shorter than 4' do
        expect(detector('12').masked).must_equal '12'
        expect(detector('').masked).must_equal ''
      end
    end

    describe '#formatted' do
      it 'groups by 4 for non-amex brands' do
        expect(visa.formatted).must_equal '4111 1111 1111 1111'
      end

      it 'groups 4-6-5 for amex' do
        expect(amex.formatted).must_equal '3782 822463 10005'
      end

      it 'uses possible_brands fallback for partial amex input' do
        # length 10, not yet a full 15-digit amex; brand returns nil but
        # possible_brands knows the leading "37" can become amex
        partial_amex = detector('3782822463')
        expect(partial_amex.brand).must_be_nil
        expect(partial_amex.formatted).must_equal '3782 822463'
      end

      it 'falls back to default 4-by-4 grouping when brand has no :segments option' do
        # simulates a user-supplied YAML that predates the :segments option:
        # the brand is registered without it, so #formatted must not crash
        # and must apply the default grouping.
        CreditCardValidations::Detector.add_brand(:my_brand, length: 16, prefixes: '8000')
        sample = CreditCardValidations::Factory.random(:my_brand)
        expect(detector(sample).brand).must_equal :my_brand
        expect(detector(sample).formatted).must_equal sample.scan(/.{4}/).join(' ')
      ensure
        CreditCardValidations::Detector.delete_brand(:my_brand)
      end

      it 'accepts a custom separator' do
        expect(visa.formatted('-')).must_equal '4111-1111-1111-1111'
      end
    end

    describe '#possible_brands' do
      it 'returns brands whose prefix matches the partial PAN' do
        expect(detector('4').possible_brands).must_include :visa
        expect(detector('37').possible_brands).must_include :amex
      end

      it 'returns all brands sharing the partial prefix' do
        # leading "5" is ambiguous across mastercard and maestro in the v9
        # default brand set (elo and dankort are opt-in plugins now)
        expect(detector('5').possible_brands.sort).must_equal %i[maestro mastercard]
      end

      it 'narrows as more digits arrive' do
        expect(detector('2').possible_brands.sort).must_equal %i[jcb mastercard]
        expect(detector('2199').possible_brands).must_equal []
      end

      it 'returns [] for empty input' do
        expect(detector('').possible_brands).must_equal []
      end

      it 'returns [] for a prefix not matching any brand' do
        expect(detector('9999').possible_brands).must_equal []
      end

      it 'reflects add_brand and delete_brand on the registry' do
        initial = detector('7').possible_brands
        CreditCardValidations::Detector.add_brand(:fictional, length: 16, prefixes: '7777')
        expect(detector('7').possible_brands).must_equal(initial + [:fictional])
        CreditCardValidations::Detector.delete_brand(:fictional)
        expect(detector('7').possible_brands).must_equal initial
      ensure
        CreditCardValidations::Detector.delete_brand(:fictional)
      end
    end
  end

  describe '#valid_cvv?' do
    it 'requires 4 digits for amex' do
      d = detector(VALID_NUMBERS[:amex].first)
      expect(d.valid_cvv?('1234')).must_equal true
      expect(d.valid_cvv?('123')).must_equal false
    end

    it 'requires 3 digits for visa and mastercard' do
      [VALID_NUMBERS[:visa].first, VALID_NUMBERS[:mastercard].first].each do |pan|
        d = detector(pan)
        expect(d.valid_cvv?('123')).must_equal true
        expect(d.valid_cvv?('1234')).must_equal false
      end
    end

    it 'rejects non-digit input' do
      d = detector(VALID_NUMBERS[:visa].first)
      expect(d.valid_cvv?('12a')).must_equal false
      expect(d.valid_cvv?(nil)).must_equal false
      expect(d.valid_cvv?('')).must_equal false
    end

    it 'returns false when brand is unknown' do
      d = detector('9999999999999999')
      expect(d.brand).must_be_nil
      expect(d.valid_cvv?('123')).must_equal false
      expect(d.valid_cvv?('1234')).must_equal false
    end

    it 'raises when detected brand has no :code option configured' do
      CreditCardValidations::Detector.add_brand(:misconfigured, length: 16, prefixes: '8001')
      sample = CreditCardValidations::Factory.random(:misconfigured)
      expect(-> { detector(sample).valid_cvv?('123') }).must_raise CreditCardValidations::Error
    ensure
      CreditCardValidations::Detector.delete_brand(:misconfigured)
    end

    it 'uses :code option from brands.yaml when present' do
      CreditCardValidations::Detector.add_brand(
        :custom_5digit_cvv, { length: 16, prefixes: '8000' },
        code: { name: 'CSC', size: 5 }
      )
      sample = CreditCardValidations::Factory.random(:custom_5digit_cvv)
      d = detector(sample)
      expect(d.brand).must_equal :custom_5digit_cvv
      expect(d.valid_cvv?('12345')).must_equal true
      expect(d.valid_cvv?('1234')).must_equal false
    ensure
      CreditCardValidations::Detector.delete_brand(:custom_5digit_cvv)
    end
  end

  it 'should support multiple brands for single check' do
    VALID_NUMBERS.slice(:visa, :mastercard).each do |key, value|
      expect(detector(value.first).brand(:visa, :mastercard)).must_equal key
    end

    VALID_NUMBERS.except(:visa, :mastercard).each do |_, value|
      expect(detector(value.first).brand(:visa, :mastercard)).must_be_nil
    end
  end

  it 'should check if valid brand without arguments' do
    VALID_NUMBERS.each do |key, value|
      load_legacy_plugin(key)
      value.each do |card_number|
        expect(detector(card_number).valid?(key)).must_equal true
        expect(assert detector(card_number).valid?).must_equal true
      end
    end
  end

  it 'should not be valid? if wrong brand' do
    expect(detector(VALID_NUMBERS[:visa].first).valid?(:mastercard)).must_equal false
    expect(detector(VALID_NUMBERS[:mastercard].first).valid?(:visa)).must_equal false
  end

  it 'should  be valid? if right brand' do
    expect(detector(VALID_NUMBERS[:visa].first).valid?(:mastercard, :visa)).must_equal true
    expect(detector(VALID_NUMBERS[:visa].first).valid?(:mastercard, :amex)).must_equal false
  end


  describe 'adding/removing brand' do

    describe 'adding rules' do

      let(:voyager_number) { '869926275400212' }

      it 'should validate number as voyager' do
        CreditCardValidations::Detector.add_brand(:voyager, length: 15, prefixes: '86')
        expect(detector(voyager_number).valid?(:voyager)).must_equal true
        expect(detector(voyager_number).voyager?).must_equal true
        expect(detector(voyager_number).brand).must_equal :voyager
        expect(detector('8').possible_brands).must_include :voyager
      end

      describe 'Add voyager rule' do
        before do
          CreditCardValidations::Detector.add_brand(:voyager, length: 15, prefixes: '86')
        end

        it 'should validate number as voyager' do
          expect(detector(voyager_number).valid?(:voyager)).must_equal true
          expect(detector(voyager_number).voyager?).must_equal true
          expect(detector(voyager_number).brand).must_equal :voyager
        end

        describe 'Remove voyager rule' do
          before do
            CreditCardValidations::Detector.delete_brand(:voyager)
          end

          it 'should not validate number as voyager' do
            expect(detector(voyager_number).respond_to?(:voyager?)).must_equal false
            expect(detector(voyager_number).brand).must_be_nil
          end
        end
      end

      describe 'Add kortimilli rule' do
        let(:kortimilli_number) { '505827028341713' }

        it 'before invoke add_brand credit card behaves like maestro' do
          expect(detector(kortimilli_number).valid?(:maestro)).must_equal true
          expect(detector(kortimilli_number).maestro?).must_equal true
          expect(detector(kortimilli_number).brand).must_equal :maestro
        end

        describe 'after adding wider prefix for kortimilli' do
          before do
            CreditCardValidations::Detector.add_brand(:kortimilli, length: 15, prefixes: '505827028')
          end

          it 'should validate number as kortimilli' do
            expect(detector(kortimilli_number).valid?(:kortimilli)).must_equal true
            expect(detector(kortimilli_number).kortimilli?).must_equal true
            expect(detector(kortimilli_number).brand).must_equal :kortimilli
          end
        end
      end
    end

    describe 'plugins' do
      [:diners_us, :en_route, :laser,
       :cabal, :dinacard, :girocard, :hiper, :humocard,
       :troy, :uatp, :uzcard, :verve, :voyager, :vpay,
       :mada, :naranja, :carnet, :cartes_bancaires].each do |brand|
        it "should support #{brand}" do
          # Sibling tests in this file dynamically `add_brand` symbols that
          # collide with shipped plugin names (notably :voyager via the
          # README tutorial example). `reload!` clears the registry hash
          # but doesn't `undef_method` the predicate, so we explicitly
          # delete the brand here to guarantee a clean slate.
          CreditCardValidations::Detector.delete_brand(brand)
          expect(-> { CreditCardValidations::Factory.random(brand) }).
            must_raise(CreditCardValidations::Error)
          custom_number = 'some_number'
          expect(detector(custom_number).respond_to?("#{brand}?")).must_equal false
          require "credit_card_validations/plugins/#{brand}"
          number = CreditCardValidations::Factory.random(brand)
          expect(detector(number).valid?("#{brand}".to_sym)).must_equal true
          expect(detector(custom_number).respond_to?("#{brand}?")).must_equal true
        end
      end
    end

    it 'should raise Error if no brand added before' do
      expect(-> { CreditCardValidations::Detector::add_rule(:undefined_brand, 20, [20]) }).
        must_raise(CreditCardValidations::Error)
    end
  end

  def luhn_valid?(number)
    CreditCardValidations::Luhn.valid?(number)
  end

  def detector(number)
    CreditCardValidations::Detector.new(number)
  end

  def has_luhn_check_rule?(key)
    CreditCardValidations::Detector.has_luhn_check_rule?(key)
  end

end
