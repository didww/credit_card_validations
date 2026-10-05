require_relative 'test_helper'

describe 'the :laser prefix list' do
  let(:detector_class) { CreditCardValidations::Detector }
  # 6771 at 16 digits, Luhn-valid.
  let(:number) { '6771890123456780' }

  before { load 'credit_card_validations/plugins/laser.rb' }
  after  { detector_class.delete_brand(:laser) }

  it 'does not claim 6771, which :maestro declares too' do
    expect(laser_prefixes).wont_include '6771'
    expect(maestro_prefixes).must_include '6771'

    expect(detector_class.new(number).valid?(:laser)).must_equal false
    expect(detector_class.new(number).valid?(:maestro)).must_equal true
  end

  # Not shared: :maestro declares 630490 and 670, resolved by prefix length.
  it 'keeps the prefixes no other brand duplicates' do
    expect(laser_prefixes).must_include '6304'
    expect(laser_prefixes).must_include '6706'

    %w[6304 6706].each do |prefix|
      pan = "#{prefix}89012345678"
      pan += CreditCardValidations::Factory.last_digit(pan).to_s
      expect(detector_class.new(pan).valid?(:laser)).must_equal true, prefix
    end
  end

  def laser_prefixes
    detector_class.brands[:laser][:rules].flat_map { |rule| rule[:prefixes] }
  end

  def maestro_prefixes
    detector_class.brands[:maestro][:rules].flat_map { |rule| rule[:prefixes] }
  end
end
