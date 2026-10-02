require_relative 'test_helper'

describe 'Detector carrying its own brand set' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:visa_only)      { detector_class.brands.slice(:visa) }
  let(:visa)           { '4111111111111111' }
  let(:mastercard)     { '5274576394259961' }
  let(:amex)           { '348051773827666' }

  it 'detects a brand that is inside its own set' do
    d = detector_class.new(visa, brands: visa_only)

    expect(d.brand).must_equal :visa
    expect(d.valid?).must_equal true
    expect(d.valid?(:visa)).must_equal true
    expect(d.brand_name).must_equal 'Visa'
  end

  it 'ignores a brand that is outside its own set' do
    d = detector_class.new(mastercard, brands: visa_only)

    expect(d.brand).must_be_nil
    expect(d.valid?).must_equal false
    expect(d.valid?(:mastercard)).must_equal false
    expect(d.brand_name).must_be_nil
    expect(d.possible_brands).must_equal []
  end

  it 'scopes possible_brands and formatted to its own set' do
    expect(detector_class.new(amex).possible_brands).must_equal [:amex]
    expect(detector_class.new(amex).formatted).must_equal '3480 517738 27666'

    scoped = detector_class.new(amex, brands: visa_only)
    expect(scoped.possible_brands).must_equal []
    expect(scoped.formatted).must_equal '3480 5177 3827 666'
  end

  it 'scopes valid_cvv? to its own set' do
    expect(detector_class.new(amex).valid_cvv?('1234')).must_equal true
    expect(detector_class.new(amex, brands: visa_only).valid_cvv?('1234')).must_equal false

    amex_only = detector_class.brands.slice(:amex)
    expect(detector_class.new(amex, brands: amex_only).valid_cvv?('1234')).must_equal true
    expect(detector_class.new(amex, brands: amex_only).valid_cvv?('123')).must_equal false
  end

  it 'resolves brand names against its own set' do
    expect(detector_class.new(visa, brands: visa_only).valid?('Visa')).must_equal true
    expect(detector_class.new(amex, brands: visa_only).valid?('American Express')).must_equal false
    expect(detector_class.new(amex).valid?('American Express')).must_equal true
  end

  it 'leaves the global registry untouched' do
    keys_before = detector_class.brands.keys

    detector_class.new(mastercard, brands: visa_only).brand

    expect(detector_class.brands.keys).must_equal keys_before
    expect(detector_class.new(mastercard).brand).must_equal :mastercard
  end

  it 'falls back to the global registry when no brands are given' do
    expect(detector_class.new(mastercard).brand).must_equal :mastercard
    expect(detector_class.new(mastercard).brands).must_equal detector_class.brands
  end

  it 'keeps the class-level lookups working off the global registry' do
    expect(detector_class.brand_name(:amex)).must_equal 'American Express'
    expect(detector_class.brand_key('American Express')).must_equal :amex
    expect(detector_class.valid_cvv?('1234', :amex)).must_equal true
    expect(detector_class.valid_cvv?('123', :amex)).must_equal false
    expect(detector_class.has_luhn_check_rule?(:visa)).must_equal true
  end
end
