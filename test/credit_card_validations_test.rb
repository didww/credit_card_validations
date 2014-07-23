require 'credit_card_validations'
require_relative 'test_helper'

class CreditCardValidationsTest < MiniTest::Test

  class CreditCardModel
    attr_accessor :number
    include ActiveModel::Validations
    validates :number, credit_card_number: {brands: [:amex, :maestro]}
  end

  class CreditCardModelAny
    attr_accessor :number
    include ActiveModel::Validations
    validates :number, presence: true, credit_card_number: true
  end

  def initialize name
    super name
    @test_numbers = {
      visa:       ['4012 8888 8888 1881','4111111111111111'],
      mastercard: ['5274 5763 9425 9961', '5555-5555-5555-4444'],
      diners:     ['3020 4169 3226 43', '30569309025904'],
      amex:       ['3782 8224 6310 005', '371449635398431'],
      discover:   ['6011 1111 1111 1117','6011000990139424'],
      maestro:    ['6759 6498 2643 8453'],
      jcb:        ['3575 7591 5225 4876', '3566002020360505' ],
      solo:       ['6767 6222 2222 2222 222'],
      unionpay:   ['6264-1852-1292-2132-067', '6288997715452584', '6269 9920 5813 4322'],
      dankrot:    ['5019717010103742']
    }
  end
  
  def test_card_brand_detection
    @test_numbers.each do |key, value|
      value.each do |card_number|
        assert detector(card_number).send("#{key}?")
        assert_equal key, detector(card_number).brand
      end
    end
  end
  
  def test_card_brand_is_nil_if_credit_card_invalid
    assert_nil detector('1111111111111111').brand
  end
  
  def test_card_brand_detection_with_restriction
    @test_numbers.slice(:visa, :mastercard).each do |key, value|
      assert_equal key, detector(value.first).brand(:visa, :mastercard)
    end
    
    @test_numbers.except(:visa, :mastercard).each do |key, value|
      assert_nil detector(value.first).brand(:visa, :mastercard)
    end
  end
  
  def test_card_valid_method
    @test_numbers.each do |key, value|
      value.each do |card_number|
        assert detector(card_number).valid?(key)
        assert detector(card_number).valid?
      end
    end
    assert !detector('1111111111111111').valid?
  end


  def test_card_particular_brand_valid
    assert !detector(@test_numbers[:visa].first).valid?(:mastercard)
    assert !detector(@test_numbers[:mastercard].first).valid?(:visa)
  end


  def test_card_particular_brands_valid
    assert detector(@test_numbers[:visa].first).valid?(:mastercard, :visa)
    assert !detector(@test_numbers[:visa].first).valid?(:mastercard, :amex)
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

  def test_active_model_validator
     cc = CreditCardModel.new
     cc.number = @test_numbers[:maestro].first
     assert cc.valid?

     cc = CreditCardModel.new
     cc.number = @test_numbers[:mastercard].first
     assert !cc.valid?
     assert cc.errors[:number].include?(cc.errors.generate_message(:number, :invalid))


    cc = CreditCardModelAny.new
    cc.number='1'
    assert !cc.valid?
    cc.number = @test_numbers[:mastercard].first
    assert cc.valid?

  end

  def test_string_extension
    require 'credit_card_validations/string'
    assert_equal  @test_numbers[:mastercard].first.credit_card_brand, :mastercard
    assert  @test_numbers[:mastercard].first.valid_credit_card_brand?(:mastercard)
    assert !@test_numbers[:mastercard].first.valid_credit_card_brand?(:visa, :amex)
  end


  def test_skip_validation
    d = detector(@test_numbers[:unionpay].first)

    d.expects(:valid_luhn?).never
    assert d.valid?(:unionpay)

    d.expects(:valid_luhn?).once
    assert !d.valid?(:visa)

    d.expects(:valid_luhn?).never
    assert d.valid?(:unionpay, :visa)

    d.expects(:valid_luhn?).once
    assert d.valid?(:visa, :unionpay)
  end

  def test_mmi
     d = detector(@test_numbers[:visa])
     assert_equal d.issuer_category, CreditCardValidations::Mmi::ISSUER_CATEGORIES[@test_numbers[:visa][0]]
  end

  protected

  def detector(number)
    CreditCardValidations::Detector.new(number)
  end


end
