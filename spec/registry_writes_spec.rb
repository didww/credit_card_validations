require_relative 'test_helper'

# The registry is one Hash for the whole process, and Hash refuses a new key
# while it is being iterated. Detection iterates it, so a write that happens
# mid-iteration used to raise -- which is what a plugin required while another
# thread is detecting does. Writers now build the new entry first and replace
# the registry with one reference assignment, so a reader walking the old hash
# is never interrupted and never sees a brand without its rules.
describe 'writing the brand registry' do
  let(:detector_class) { CreditCardValidations::Detector }

  after do
    %i[my_own other].each { |brand| detector_class.delete_brand(brand) }
    CreditCardValidations.reload!
  end

  it 'allows add_brand while the registry is being iterated' do
    detector_class.brands.each_with_index do |_, index|
      CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: '99' }) if index.zero?
    end

    expect(detector_class.brands.keys).must_include :my_own
  end

  it 'allows add_rule while the registry is being iterated' do
    detector_class.brands.each_with_index do |_, index|
      detector_class.add_rule(:visa, 16, ['99']) if index.zero?
    end

    expect(detector_class.new('9911111111111112').valid?(:visa)).must_equal true
  end

  it 'allows delete_brand while the registry is being iterated' do
    detector_class.brands.each_with_index do |_, index|
      detector_class.delete_brand(:maestro) if index.zero?
    end

    expect(detector_class.brands.keys).wont_include :maestro
  end

  it 'allows a write part-way through the registry, not only at the start' do
    CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: '99' })

    detector_class.brands.each_key do |key|
      CreditCardValidations.add_brand(:other, { length: 16, prefixes: '98' }) if key == :my_own
    end

    expect(detector_class.brands.keys).must_include :other
  end

  it 'publishes a brand complete with its rules, never partly built' do
    rules = 3.times.map { |i| { length: 16, prefixes: "9#{i}" } }
    CreditCardValidations.add_brand(:my_own, rules)

    expect(detector_class.brands[:my_own][:rules].size).must_equal 3
  end

  it 'leaves a registry a caller already holds untouched' do
    before = detector_class.brands

    CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: '99' })

    expect(before.keys).wont_include :my_own
    expect(detector_class.brands.keys).must_include :my_own
    expect(before).wont_be_same_as detector_class.brands
  end
end
