require_relative 'test_helper'

class CreditCardValidationsTest < MiniTest::Test


  def initialize name
    super name
    @test_valid_numbers = {
      visa: ['4012 8888 8888 1881', 4111111111111111, '4222 2222 2222 2'],
      mastercard: ['5274 5763 9425 9961', '5555-5555-5555-4444', '5105 1051 0510 5100'],
      diners: ['3020 4169 3226 43', '30569309025904', '38520000023237'],
      amex: ['3782 8224 6310 005', '371449635398431', '3787 3449 3671 000'],
      discover: ['6011 1111 1111 1117', '6011000990139424'],
      maestro: ['6759 6498 2643 8453'],
      jcb: ['3575 7591 5225 4876', '3566002020360505'],
      solo: ['6767 6222 2222 2222 222'],
      unionpay: ['6264-1852-1292-2132-067', '6288997715452584', '6269 9920 5813 4322'],
      dankrot: ['5019717010103742'],
      switch: ['6331101999990016'],
      rupay: ['6076-6000-0619-9992', '6070-5500-5000-0047'],
      hipercard: ['3841005899088180330']
    }
    
    @test_invalid_numbers = ['1111111111111111', '00000000000000', "fakenumber", "c4111111111111111", '4111111111111111i']
  end

  def test_card_if_credit_card_valid
    @test_valid_numbers.each do |brand, card_numbers|
      card_numbers.each do |card_number|
        assert detector(card_number).send("#{brand}?")
        assert_equal brand, detector(card_number).brand
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

  def detector(number)
    CreditCardValidations::Detector.new(number)
  end


end
