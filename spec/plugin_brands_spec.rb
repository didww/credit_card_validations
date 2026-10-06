require_relative 'test_helper'

# The seven brands below left the default set in v9.0 and were kept working by
# an auto-require shim that loaded the plugin on first reference and warned
# once. v10.0 removes the shim: naming one of these brands without requiring
# its plugin now behaves exactly like naming a brand that never existed.
describe 'Brands that live only in plugins' do
  let(:detector_class) { CreditCardValidations::Detector }

  PLUGIN_ONLY_BRANDS = %i[mir rupay elo dankort hipercard solo switch].freeze

  # Loading a plugin defines its predicate method on the class, and reload!
  # does not take that back: it assigns `brands = {}` and refills from the
  # yaml, never going through undef_brand_method. delete_brand does both, so
  # it has to come first -- otherwise these examples pass or fail depending on
  # which one minitest happened to run before them.
  #
  # reload! afterwards only restores the default brands; the seven plugin
  # brands are not in the yaml, so it cannot bring them back.
  before { reset_plugin_brands }
  after  { reset_plugin_brands }

  def reset_plugin_brands
    PLUGIN_ONLY_BRANDS.each { |brand| detector_class.delete_brand(brand) }
    CreditCardValidations.reload!
  end

  it 'are absent from the default brand set' do
    PLUGIN_ONLY_BRANDS.each do |brand|
      expect(detector_class.brands.key?(brand)).must_equal false, "#{brand} should not be loaded by default"
    end
  end

  it 'are not auto-loaded when referenced, and warn about nothing' do
    out, err = capture_io do
      @valid = detector_class.new('2202 1234 1234 1234').valid?(:mir)
    end

    expect(err).must_be_empty
    expect(out).must_be_empty
    expect(@valid).must_equal false
    expect(detector_class.brands.key?(:mir)).must_equal false
  end

  it 'leave #brand nil for a number only they would match' do
    _, err = capture_io { @brand = detector_class.new('2202 1234 1234 1234').brand }

    expect(err).must_be_empty
    expect(@brand).must_be_nil
  end

  it 'do not define their predicate method until the plugin is required' do
    expect(detector_class.new('2202 1234 1234 1234').respond_to?(:mir?)).must_equal false
  end

  it 'work normally once the plugin is required' do
    load_plugin(:mir)

    detector = detector_class.new('2202 1234 1234 1234')
    expect(detector_class.brands.key?(:mir)).must_equal true
    expect(detector.valid?(:mir)).must_equal true
    expect(detector.brand).must_equal :mir
  end

  # One assertion per example: minitest stops an example at its first failed
  # assertion, and each of these three can rot independently.
  describe 'no longer expose the shim' do
    # `false` restricts the lookup to Detector itself. Without it the search
    # walks up to Object, so any top-level LEGACY_PLUGIN_BRANDS -- this very
    # file defines a top-level PLUGIN_ONLY_BRANDS -- would satisfy the check.
    it 'has no LEGACY_PLUGIN_BRANDS constant of its own' do
      expect(detector_class.const_defined?(:LEGACY_PLUGIN_BRANDS, false)).must_equal false
    end

    it 'has no @@legacy_autoloaded class variable' do
      expect(detector_class.class_variable_defined?(:@@legacy_autoloaded)).must_equal false
    end

    # method_defined? covers public and protected. The shim method was
    # protected, so private_method_defined? answered false while it still
    # existed -- the assertion could not fail.
    it 'has no autoload_legacy_plugin method' do
      expect(detector_class.method_defined?(:autoload_legacy_plugin)).must_equal false
      expect(detector_class.private_method_defined?(:autoload_legacy_plugin)).must_equal false
    end
  end
end
