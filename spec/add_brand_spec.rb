require_relative 'test_helper'

describe 'CreditCardValidations.add_brand' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:visa)           { '4111111111111111' }

  after do
    detector_class.delete_brand(:my_own)
    CreditCardValidations.reload!
  end

  it 'registers a brand that is not in the registry yet' do
    CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: '9' },
                                    { code: { name: 'CVV', size: 3 } })

    expect(detector_class.brands).must_include :my_own
    expect(detector_class.new('9111111111111110').brand).must_equal :my_own
  end

  # The method replaces the whole entry, so redefining a brand used to drop
  # everything the call did not mention: its rules, and with them its name,
  # CVV size, segments and skip_luhn opt-out. Nothing warned, and the brand
  # stopped detecting its own cards.
  it 'refuses to redefine a brand that is already registered' do
    error = expect(-> { CreditCardValidations.add_brand(:visa, { length: 16, prefixes: '9' }) })
            .must_raise CreditCardValidations::Error

    expect(error.message).must_match(/:visa is already registered/)
  end

  it 'leaves the brand untouched when it refuses' do
    begin
      CreditCardValidations.add_brand(:visa, { length: 16, prefixes: '9' })
    rescue CreditCardValidations::Error
      nil
    end

    expect(detector_class.new(visa).valid?(:visa)).must_equal true
    expect(detector_class.brand_name(:visa)).must_equal 'Visa'
    expect(detector_class.valid_cvv?('123', :visa)).must_equal true
  end

  it 'takes delete_brand first to replace one on purpose' do
    detector_class.delete_brand(:visa)
    CreditCardValidations.add_brand(:visa, { length: 16, prefixes: '9' })

    expect(detector_class.new('9111111111111110').brand).must_equal :visa
    expect(detector_class.new(visa).valid?(:visa)).must_equal false
  end

  it 'still lets add_rule widen a registered brand' do
    detector_class.add_rule(:visa, 16, ['9'])

    expect(detector_class.new('9111111111111110').valid?(:visa)).must_equal true
    expect(detector_class.new(visa).valid?(:visa)).must_equal true
    expect(detector_class.brand_name(:visa)).must_equal 'Visa'
  end

  it 'is not tripped by reload!, which empties the registry first' do
    CreditCardValidations.reload!
    CreditCardValidations.reload!

    expect(detector_class.new(visa).valid?(:visa)).must_equal true
  end

  it 'does not define the predicate method when it refuses' do
    detector_class.delete_brand(:my_own)
    expect(-> { CreditCardValidations.add_brand(:visa, { length: 16, prefixes: '9' }) })
      .must_raise CreditCardValidations::Error

    # add_brand defines <key>? last, so a guard placed after the write would
    # leave a half-registered brand behind.
    expect(detector_class.new(visa).respond_to?(:visa?)).must_equal true
    expect(detector_class.new(visa).visa?).must_equal true
  end
end
