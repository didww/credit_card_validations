require 'test/unit'
lib = File.expand_path("#{File.dirname(__FILE__)}/../lib")
unit_tests = File.expand_path("#{File.dirname(__FILE__)}/../test")
$:.unshift(lib)
$:.unshift(unit_tests)

require 'credit_card_validations'

class CreditCardValidationsTest < Test::Unit::TestCase

  class CreditCardModel
    attr_accessor :number
    include ActiveModel::Validations
    validates :number, credit_card_number: {brands: [:amex, :maestro]}
  end

  def initialize name
    super name
    @test_numbers = {
        visa: '4012 8888 8888 1881',
        mastercard: '5274 5763 9425 9961',
        diners: '3020 4169 3226 43',
        amex: '3782 8224 6310 005',
        discover: '6011 1111 1111 1117',
        maestro: '6759 6498 2643 8453',
        jcb: '3575 7591 5225 4876',
        solo: '6767 6222 2222 2222 222',
        unionpay: '6264-1852-1292-2132-067',

    }
  end

  def test_card_brand_detection
    @test_numbers.each do |key, value|
      assert_equal key, detector(value).brand
      assert detector(value).send("#{key}?")
    end
  end

  def test_card_brand_is_nil_if_credit_card_invalid
    assert_nil detector('1111111111111111').brand
  end

  def test_card_valid_method
    @test_numbers.each do |key, value|
      assert detector(value).valid?(key)
      assert detector(value).valid?
    end
    assert !detector('1111111111111111').valid?
  end


  def test_card_particular_brand_valid
    assert !detector(@test_numbers[:visa]).valid?(:mastercard)
    assert !detector(@test_numbers[:mastercard]).valid?(:visa)
  end


  def test_card_particular_brands_valid
    assert detector(@test_numbers[:visa]).valid?(:mastercard, :visa)
    assert !detector(@test_numbers[:visa]).valid?(:mastercard, :amex)
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
     cc.number = @test_numbers[:maestro]
     assert cc.valid?
      
     cc = CreditCardModel.new
     cc.number = @test_numbers[:mastercard]
     assert !cc.valid?
     assert cc.errors[:number].include?(cc.errors.generate_message(:number, :invalid))
  end
  
  def test_string_extension
    require 'credit_card_validations/string'
    assert_equal  @test_numbers[:mastercard].credit_card_brand, :mastercard  
    assert  @test_numbers[:mastercard].valid_credit_card_brand?(:mastercard)  
    assert !@test_numbers[:mastercard].valid_credit_card_brand?(:visa, :amex)  
  end  
  
  protected

  def detector(number)
    CreditCardValidations::Detector.new(number)
  end


end