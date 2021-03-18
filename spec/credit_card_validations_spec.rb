require_relative 'test_helper'

describe CreditCardValidations do


  before do
    CreditCardValidations.reload!
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

  end


  it 'should check luhn' do
    VALID_NUMBERS.each do |brand, card_numbers|
      if has_luhn_check_rule?(brand)
        card_numbers.each do |number|
          expect(luhn_valid?(detector(number).number)).must_equal true
        end
      end
    end
  end

  it 'should check valid brand' do
    VALID_NUMBERS.each do |brand, card_numbers|
      card_numbers.each do |card_number|
        expect(detector(card_number).send("#{brand}?")).must_equal true
        expect(detector(card_number).brand).must_equal brand
      end
    end
  end

  it 'should check if card invalid' do
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
    end

    describe 'plugins' do
      [:diners_us, :en_route, :laser].each do |brand|
        it "should support #{brand}" do
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
