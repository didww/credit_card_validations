require_relative 'test_helper'
require 'tmpdir'

describe CreditCardValidations::BrandSet do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:visa)           { '4111111111111111' }
  let(:mastercard)     { '5274576394259961' }
  let(:amex)           { '348051773827666' }
  let(:dankort)        { '5019717010103742' }

  # Loading a plugin registers the brand globally and defines a predicate on
  # Detector that reload! does not remove — only delete_brand does. Reset both
  # sides around every example so the file runs in any order.
  before { detector_class.delete_brand(:dankort) }

  after do
    detector_class.delete_brand(:dankort)
    CreditCardValidations.reset
    CreditCardValidations.reload!
  end

  describe '#detect' do
    it 'answers for a brand in the set' do
      set = CreditCardValidations.with_brands(:visa, :mastercard)

      expect(set.detect(visa).brand).must_equal :visa
      expect(set.detect(mastercard).brand).must_equal :mastercard
      expect(set.detect(visa).valid?).must_equal true
      expect(set.detect(visa).valid?(:visa)).must_equal true
    end

    it 'answers nil for a brand outside the set' do
      set = CreditCardValidations.with_brands(:visa)

      expect(set.detect(mastercard).brand).must_be_nil
      expect(set.detect(mastercard).valid?).must_equal false
      expect(set.detect(mastercard).valid?(:mastercard)).must_equal false
      expect(set.detect(mastercard).brand_name).must_be_nil
    end

    it 'returns a Detector, so the whole instance API scopes with it' do
      set = CreditCardValidations.with_brands(:visa)
      detector = set.detect(amex)

      expect(detector).must_be_kind_of detector_class
      expect(detector.possible_brands).must_equal []
      expect(detector.valid_cvv?('1234')).must_equal false
      expect(detector.valid?('American Express')).must_equal false
      # No :segments from the set, so formatted falls back to groups of four.
      expect(detector.formatted).must_equal '3480 5177 3827 666'
    end

    it 'scopes brand_name, valid_cvv? and formatted to the set' do
      set = CreditCardValidations.with_brands(:amex)

      expect(set.detect(amex).brand_name).must_equal 'American Express'
      expect(set.detect(amex).valid_cvv?('1234')).must_equal true
      expect(set.detect(amex).valid_cvv?('123')).must_equal false
      expect(set.detect(amex).formatted).must_equal '3480 517738 27666'
      expect(set.detect(amex).valid?('American Express')).must_equal true
    end

    it 'keeps two sets in one process independent of each other' do
      a = CreditCardValidations.with_brands(:visa)
      b = CreditCardValidations.with_brands(:mastercard)

      expect(a.detect(visa).brand).must_equal :visa
      expect(a.detect(mastercard).brand).must_be_nil
      expect(b.detect(mastercard).brand).must_equal :mastercard
      expect(b.detect(visa).brand).must_be_nil

      # Again, to show neither degraded after the other was used.
      expect(a.brands).must_equal [:visa]
      expect(b.brands).must_equal [:mastercard]
    end

    it 'leaves the global registry alone' do
      keys_before = detector_class.brands.keys
      set = CreditCardValidations.with_brands(:visa)

      set.detect(mastercard).brand
      set.detect(visa).brand

      expect(detector_class.brands.keys).must_equal keys_before
      expect(detector_class.new(mastercard).brand).must_equal :mastercard
      expect(detector_class.brand_name(:amex)).must_equal 'American Express'
    end
  end

  describe '#brands' do
    it 'lists the keys in the order they were requested' do
      expect(CreditCardValidations.with_brands(:mastercard, :visa).brands)
        .must_equal [:mastercard, :visa]
    end

    it 'is frozen, so the set cannot be edited through it' do
      set = CreditCardValidations.with_brands(:visa, :mastercard)

      expect(set.brands).must_be :frozen?
      expect { set.brands.clear }.must_raise FrozenError
      expect(set.detect(mastercard).brand).must_equal :mastercard
    end
  end

  describe 'keys' do
    it 'takes a symbol or a string, in any case' do
      [:visa, 'visa', :VISA, 'VISA', :Visa].each do |key|
        expect(CreditCardValidations.with_brands(key).brands).must_equal [:visa]
      end
    end

    it 'takes a key only, not a brand name' do
      # Detector#valid? resolves a display name to a key; with_brands does not.
      # Detector.brand_key only matches an explicit :brand_name option and
      # misses the titleized-key fallback, so supporting names here would work
      # for some brands and raise for others.
      error = expect(-> { CreditCardValidations.with_brands('American Express') })
              .must_raise CreditCardValidations::Error

      expect(error.message).must_match(/american express/)
    end


    it 'accepts a flat list or an array' do
      expect(CreditCardValidations.with_brands(:visa, :mastercard).brands)
        .must_equal CreditCardValidations.with_brands([:visa, :mastercard]).brands
    end

    it 'raises on an unknown key instead of dropping it' do
      # A dropped brand would mean a valid card is quietly rejected.
      error = expect(-> { CreditCardValidations.with_brands(:visa, :nope) })
              .must_raise CreditCardValidations::Error

      expect(error.message).must_match(/nope/)
    end

    it 'raises for a plugin brand whose plugin was never required' do
      expect(detector_class.brands).wont_include :dankort

      error = expect(-> { CreditCardValidations.with_brands(:visa, :dankort) })
              .must_raise CreditCardValidations::Error

      expect(error.message).must_match(/dankort/)
      expect(detector_class.brands).wont_include :dankort
    end

    it 'accepts a plugin brand once its plugin is required' do
      load 'credit_card_validations/plugins/dankort.rb'

      set = CreditCardValidations.with_brands(:visa, :dankort)

      expect(set.brands).must_equal [:visa, :dankort]
      expect(set.detect(dankort).brand).must_equal :dankort
      expect(set.detect(mastercard).brand).must_be_nil
    end

    it 'raises on an empty list rather than building a set that accepts nothing' do
      error = expect(-> { CreditCardValidations.with_brands })
              .must_raise CreditCardValidations::Error

      expect(error.message).must_match(/at least one brand/)
      expect(-> { CreditCardValidations.with_brands([]) })
        .must_raise CreditCardValidations::Error
    end
  end

  # A set narrows which brands are considered, not what they are. One card must
  # not get different answers from different objects in one process, so the
  # definitions are read live rather than copied at construction.
  describe 'brand definitions' do
    it 'follows add_rule on a brand in the set' do
      set = CreditCardValidations.with_brands(:visa, :mastercard)

      detector_class.add_rule(:visa, 16, ['5274'])

      expect(set.detect(mastercard).brand).must_equal :visa
      expect(detector_class.new(mastercard).brand).must_equal :visa
    end

    it 'follows a replaced brand source' do
      set = CreditCardValidations.with_brands(:amex)
      expect(set.detect(amex).valid_cvv?('1234')).must_equal true

      with_amex_cvv_size(3) do
        expect(set.detect(amex).valid_cvv?('1234')).must_equal false
        expect(set.detect(amex).valid_cvv?('123')).must_equal true
        expect(detector_class.valid_cvv?('123', :amex)).must_equal true
      end
    end

    it 'follows delete_brand, leaving the key listed but undetectable' do
      set = CreditCardValidations.with_brands(:visa, :mastercard)

      detector_class.delete_brand(:mastercard)

      expect(set.brands).must_equal [:visa, :mastercard]
      expect(set.detect(mastercard).brand).must_be_nil
      expect(set.detect(visa).brand).must_equal :visa
    end

    it 'never answers differently from an unscoped detector about a brand both see' do
      set = CreditCardValidations.with_brands(:amex)

      with_amex_cvv_size(3) do
        %w[123 1234].each do |code|
          expect(set.detect(amex).valid_cvv?(code))
            .must_equal detector_class.new(amex).valid_cvv?(code), "CVV #{code}"
        end
        expect(set.detect(amex).brand_name).must_equal detector_class.brand_name(:amex)
      end
    end

    # The documented way to override brand data: copy the bundled yaml, edit
    # it, and point the gem at it.
    def with_amex_cvv_size(size)
      data = YAML.safe_load_file(CreditCardValidations.source, permitted_classes: [Symbol])
      data[:amex][:options][:code] = { name: 'CID', size: size }
      file = File.join(Dir.tmpdir, "brands_amex_cvv_#{size}.yml")
      File.write(file, data.to_yaml)

      CreditCardValidations.configure { |config| config.source = file }
      yield
    ensure
      File.delete(file) if file && File.exist?(file)
      CreditCardValidations.reset
      CreditCardValidations.reload!
    end
  end

  describe 'what stays global' do
    it 'keeps the class-level lookups on the global registry' do
      CreditCardValidations.with_brands(:visa)

      expect(detector_class.brands.keys).must_include :mastercard
      expect(detector_class.brand_name(:amex)).must_equal 'American Express'
      expect(detector_class.brand_key('American Express')).must_equal :amex
      expect(detector_class.valid_cvv?('1234', :amex)).must_equal true
      expect(detector_class.has_luhn_check_rule?(:visa)).must_equal true
    end

    it 'keeps which predicate methods exist global, while their answer scopes' do
      set = CreditCardValidations.with_brands(:visa)

      # add_brand defines the predicate on Detector, so a scoped detector still
      # responds to it -- with false, since the brand is outside the set.
      expect(set.detect(mastercard).respond_to?(:mastercard?)).must_equal true
      expect(set.detect(mastercard).mastercard?).must_equal false
      expect(set.detect(visa).visa?).must_equal true

      detector_class.delete_brand(:mastercard)
      expect(set.detect(mastercard).respond_to?(:mastercard?)).must_equal false
    end

    it 'leaves a subclass override of the class-level lookups working' do
      # Instance lookups go through self.class, as they always have. Nothing
      # about brand sets changes that.
      subclass = Class.new(detector_class) do
        def self.brand_name(_brand_key) = 'Renamed'
      end

      expect(subclass.new(visa).brand_name).must_equal 'Renamed'
      expect(detector_class.new(visa).brand_name).must_equal 'Visa'
    end
  end
end
