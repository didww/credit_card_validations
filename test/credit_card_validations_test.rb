require_relative 'test_helper'
require 'yaml'

class CreditCardValidationsTest < MiniTest::Test


  def initialize name
    super name
    @test_valid_numbers = YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/valid_cards.yml')
    @test_invalid_numbers = YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/invalid_cards.yml')
  end


  def test_card_luhn
    @test_valid_numbers.each do |brand, card_numbers|
      if has_luhn_check_rule?(brand)
        card_numbers.each do |number|
          assert luhn_valid?(detector(number).number), "#{number} failed luhn"
        end
      end
    end

  end

  def test_card_if_credit_card_valid
    @test_valid_numbers.each do |brand, card_numbers|
      card_numbers.each do |card_number|
        assert detector(card_number).send("#{brand}?"), "#{card_number} is #{brand}"
        assert_equal brand, detector(card_number).brand, "#{card_number} detects as #{brand}"
      end
    end
  end

  def test_card_if_credit_card_invalid
    @test_invalid_numbers.each do |card_number|
      assert !detector(card_number).valid?
      assert_nil detector(card_number).brand
      @test_valid_numbers.keys.each do |brand|
        assert !detector(card_number).send("#{brand}?")
      end
    end
  end

  def test_card_brand_detection_with_restriction
    @test_valid_numbers.slice(:visa, :mastercard).each do |key, value|
      assert_equal key, detector(value.first).brand(:visa, :mastercard)
    end

    @test_valid_numbers.except(:visa, :mastercard).each do |key, value|
      assert_nil detector(value.first).brand(:visa, :mastercard)
    end
  end

  def test_card_valid_method
    @test_valid_numbers.each do |key, value|
      value.each do |card_number|
        assert detector(card_number).valid?(key)
        assert detector(card_number).valid?
      end
    end
  end

  def test_card_particular_brand_valid
    assert !detector(@test_valid_numbers[:visa].first).valid?(:mastercard)
    assert !detector(@test_valid_numbers[:mastercard].first).valid?(:visa)
  end

  def test_card_particular_brands_valid
    assert detector(@test_valid_numbers[:visa].first).valid?(:mastercard, :visa)
    assert !detector(@test_valid_numbers[:visa].first).valid?(:mastercard, :amex)
  end

  #add rules which were not present before
  def test_card_valid_after_rules_added
    voyager_test_card_number = '869926275400212'
    assert !detector(voyager_test_card_number).valid?
    CreditCardValidations::Detector.add_rule(:voyager, 15, '86')
    assert detector(voyager_test_card_number).valid?
    assert_equal :voyager, detector(voyager_test_card_number).brand
    assert detector(voyager_test_card_number).voyager?
    assert !detector(voyager_test_card_number).visa?
    assert !detector(voyager_test_card_number).mastercard?
  end

  def test_active_model_any_validator
    cc = AnyCreditCard.new
    cc.number='1'
    assert !cc.valid?
    cc.number = @test_valid_numbers[:mastercard].first
    assert cc.valid?
  end

  def test_active_model_validator
    cc = CreditCard.new
    cc.number = @test_valid_numbers[:maestro].first
    assert cc.valid?

    cc = CreditCard.new
    cc.number = @test_valid_numbers[:mastercard].first
    assert !cc.valid?
    assert cc.errors[:number].include?(cc.errors.generate_message(:number, :invalid))

  end

  def test_string_extension
    assert !@test_valid_numbers[:mastercard].first.respond_to?(:credit_card_brand)
    assert !@test_valid_numbers[:mastercard].first.respond_to?(:valid_credit_card_brand?)
    require 'credit_card_validations/string'
    assert_equal @test_valid_numbers[:mastercard].first.credit_card_brand, :mastercard
    assert @test_valid_numbers[:mastercard].first.valid_credit_card_brand?(:mastercard)
    assert !@test_valid_numbers[:mastercard].first.valid_credit_card_brand?(:visa, :amex)
  end

  def test_call_luhn
    d = detector(@test_valid_numbers[:unionpay].first)
    d.expects(:valid_luhn?).once
    assert !d.valid?(:visa)

    d.expects(:valid_luhn?).once
    assert d.valid?(:visa, :unionpay)
  end

  def test_skip_luhn
    d = detector(@test_valid_numbers[:unionpay].first)
    d.expects(:valid_luhn?).never
    assert d.valid?(:unionpay)
    d.expects(:valid_luhn?).never
    assert d.valid?(:unionpay, :visa)
  end

  def test_mmi
    d = detector(@test_valid_numbers[:visa].first)
    assert_equal d.issuer_category, CreditCardValidations::Mmi::ISSUER_CATEGORIES[d.number[0]]
  end

  protected

  def luhn_valid?(number)
    CreditCardValidations::Luhn.valid?(number)
  end

  def detector(number)
    CreditCardValidations::Detector.new(number)
  end


  def has_luhn_check_rule?(brand)
    CreditCardValidations::Detector.rules[brand].any? { |rule| !rule[:skip_luhn] }
  end

end
