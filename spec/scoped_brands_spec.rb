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

describe 'CreditCardValidations.with_brands' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:visa)           { '4111111111111111' }
  let(:mastercard)     { '5274576394259961' }
  let(:amex)           { '348051773827666' }
  let(:dankort)        { '5019717010103742' }

  # Loading a plugin registers the brand globally and defines a predicate
  # method on Detector that reload! does not remove — only delete_brand does.
  # Reset it around every example so this spec can run in any order.
  before do
    detector_class.delete_brand(:dankort)
  end

  after do
    detector_class.delete_brand(:dankort)
    CreditCardValidations.reload!
  end

  it 'detects only the brands it was given' do
    set = CreditCardValidations.with_brands(:visa, :mastercard)

    expect(set.brands).must_equal [:visa, :mastercard]
    expect(set.detect('4111 1111 1111 1111').brand).must_equal :visa
    expect(set.detect('5274 5763 9425 9961').brand).must_equal :mastercard
    expect(set.detect(amex).brand).must_be_nil
    expect(set.detect(amex).valid?).must_equal false
  end

  it 'accepts string keys and brand names' do
    set = CreditCardValidations.with_brands('visa', 'American Express')

    expect(set.brands).must_equal [:visa, :amex]
    expect(set.detect(amex).brand).must_equal :amex
  end

  it 'keeps two sets in the same process isolated from each other' do
    merchant_a = CreditCardValidations.with_brands(:visa)
    merchant_b = CreditCardValidations.with_brands(:mastercard)

    expect(merchant_a.detect(visa).brand).must_equal :visa
    expect(merchant_a.detect(mastercard).brand).must_be_nil
    expect(merchant_b.detect(mastercard).brand).must_equal :mastercard
    expect(merchant_b.detect(visa).brand).must_be_nil

    # and again, to prove neither set degraded after the other was used
    expect(merchant_a.brands).must_equal [:visa]
    expect(merchant_b.brands).must_equal [:mastercard]
  end

  it 'leaves the global registry untouched' do
    keys_before = detector_class.brands.keys

    set = CreditCardValidations.with_brands(:visa)
    set.detect(mastercard).brand
    set.detect(visa).brand

    expect(detector_class.brands.keys).must_equal keys_before
    expect(detector_class.new(mastercard).brand).must_equal :mastercard
    expect(detector_class.new(amex).valid?(:amex)).must_equal true
  end

  it 'raises on an unknown brand key' do
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
end

describe 'a brand set is a snapshot, not a view of the global registry' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:visa)           { '4111111111111111' }
  let(:mastercard)     { '5274576394259961' }

  # Every example here either writes the global registry or writes through the
  # set, so rebuild the registry from brands.yaml afterwards.
  after { CreditCardValidations.reload! }

  # The set's brand hash, reached the way the rest of the API reaches it.
  def scoped_brands(set)
    set.detect('').brands
  end

  it 'does not share brand definitions with the global registry' do
    scoped = scoped_brands(CreditCardValidations.with_brands(:visa))[:visa]
    global = detector_class.brands[:visa]

    expect(scoped).must_equal global
    expect(scoped).wont_be_same_as global
    expect(scoped[:rules]).wont_be_same_as global[:rules]
    expect(scoped[:options]).wont_be_same_as global[:options]
  end

  it 'is not widened by a global add_rule after construction' do
    set = CreditCardValidations.with_brands(:visa)

    detector_class.add_rule(:visa, 16, ['5274'])

    expect(set.detect(mastercard).brand).must_be_nil
    expect(detector_class.new(mastercard).brand).must_equal :visa
  end

  it 'is not narrowed by a global delete_brand after construction' do
    set = CreditCardValidations.with_brands(:visa, :mastercard)

    detector_class.delete_brand(:mastercard)

    expect(set.detect(mastercard).brand).must_equal :mastercard
  end

  it 'cannot be written through at all, so neither it nor the global registry can be corrupted' do
    set = CreditCardValidations.with_brands(:visa)

    expect { scoped_brands(set)[:visa][:rules].clear }.must_raise FrozenError

    expect(detector_class.new(visa).brand).must_equal :visa
    expect(set.detect(visa).brand).must_equal :visa
  end
end

describe 'a Detector scoped through the brands= writer' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:visa)           { '4111111111111111' }

  # Auto-loading :dankort registers it globally and defines #dankort?, which
  # reload! does not undo. Reset both sides around every example.
  before { reset_dankort }

  after do
    reset_dankort
    CreditCardValidations.reload!
  end

  def reset_dankort
    detector_class.delete_brand(:dankort)
  end

  it 'does not write the global registry' do
    detector = detector_class.new(visa)
    detector.brands = detector_class.brands.slice(:visa)

    expect(detector.valid?(:dankort)).must_equal false
    expect(detector_class.brands).wont_include :dankort
  end
end

describe 'an override of the class-level lookups' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:visa)           { '4111111111111111' }

  # Up to v9 Detector#brand_name and #valid_cvv? dispatched through
  # self.class, so an app subclassing Detector to rename a brand or to widen
  # CVV validation had its override honoured. A detector on the global
  # registry must keep behaving that way.
  let(:subclass) do
    Class.new(detector_class) do
      def self.brand_name(_brand_key) = 'Renamed'
      def self.brand_key(_brand_name) = :visa
      def self.valid_cvv?(_code, _brand) = :from_the_override
    end
  end

  it 'still wins for a detector on the global registry' do
    detector = subclass.new(visa)

    expect(detector.brand_name).must_equal 'Renamed'
    expect(detector.valid_cvv?('123')).must_equal :from_the_override
    # valid? with a String resolves it through .brand_key, so the override
    # decides which brand a name means.
    expect(detector.valid?('Whatever The App Calls It')).must_equal true
  end

  it 'also wins when defined on one detector only' do
    detector = detector_class.new(visa)
    detector.define_singleton_method(:brand_name) { 'Per instance' }

    expect(detector.brand_name).must_equal 'Per instance'
  end

  it 'is bypassed by a scoped detector, whose registry the class cannot see' do
    detector = subclass.new(visa, brands: detector_class.brands.slice(:visa))

    # Honouring it would mean calling a one-argument override that can only
    # read the global registry -- the wrong answers for a scoped set.
    expect(detector.brand_name).must_equal 'Visa'
    expect(detector.valid_cvv?('123')).must_equal true
    expect(detector.valid?('Whatever The App Calls It')).must_equal false
  end
end

describe 'brand names that fall back to the titleized key' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:en_route)       { '201401234567890' }

  # :en_route ships without an explicit :brand_name, so its display name comes
  # from the key.to_s.titleize fallback in Lookups.brand_name. A single-word
  # key survives the gap by accident -- downcasing the name happens to give
  # the key back -- so pin it with a key that titleizes to two words.
  before { load 'credit_card_validations/plugins/en_route.rb' }
  after  { detector_class.delete_brand(:en_route) }

  it 'round-trips a fallback brand name back to its key' do
    expect(detector_class.brand_name(:en_route)).must_equal 'En Route'
    expect(detector_class.brand_key('En Route')).must_equal :en_route
  end

  it 'accepts a fallback brand name in with_brands' do
    set = CreditCardValidations.with_brands('En Route')

    expect(set.brands).must_equal [:en_route]
    expect(set.detect(en_route).brand).must_equal :en_route
  end

  it 'accepts a fallback brand name in valid?' do
    expect(detector_class.new(en_route).valid?('En Route')).must_equal true
  end

  it 'looks names up in a brand hash that carries no :options' do
    detector = detector_class.new(en_route, brands: {en_route: {rules: []}})

    expect(detector.valid?('En Route')).must_equal false
  end
end

describe 'CreditCardValidations.with_brands with no keys' do
  it 'raises instead of building a set that accepts nothing' do
    error = expect(-> { CreditCardValidations.with_brands })
            .must_raise CreditCardValidations::Error

    expect(error.message).must_match(/at least one brand/)
  end

  it 'raises for an empty array too' do
    expect(-> { CreditCardValidations.with_brands([]) })
      .must_raise CreditCardValidations::Error
  end
end

describe 'a brand set keeps every lookup on its own snapshot' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:amex)           { '348051773827666' }

  after { CreditCardValidations.reload! }

  # In-place writes, the kind add_rule and a hand-edited registry do. These
  # are the writes that reach a set built by reference; an add_brand/
  # delete_brand replaces the global entry wholesale and never could.
  def rewrite_global_amex
    options = detector_class.brands[:amex][:options]
    options[:brand_name] = 'Renamed'
    options[:segments]   = [5, 5, 5]
    options[:code]       = {name: 'CID', size: 3}
  end

  it 'reads brand_name from the snapshot' do
    set = CreditCardValidations.with_brands(:amex)
    rewrite_global_amex

    expect(set.detect(amex).brand_name).must_equal 'American Express'
    expect(detector_class.brand_name(:amex)).must_equal 'Renamed'
  end

  it 'reads valid_cvv? from the snapshot' do
    set = CreditCardValidations.with_brands(:amex)
    rewrite_global_amex

    expect(set.detect(amex).valid_cvv?('1234')).must_equal true
    expect(set.detect(amex).valid_cvv?('123')).must_equal false
    expect(detector_class.valid_cvv?('123', :amex)).must_equal true
  end

  it 'reads formatted from the snapshot' do
    set = CreditCardValidations.with_brands(:amex)
    rewrite_global_amex

    expect(set.detect(amex).formatted).must_equal '3480 517738 27666'
    expect(detector_class.new(amex).formatted).must_equal '34805 17738 27666'
  end

  it 'resolves brand names against the snapshot' do
    set = CreditCardValidations.with_brands(:amex)
    rewrite_global_amex

    expect(set.detect(amex).valid?('American Express')).must_equal true
    expect(detector_class.new(amex).valid?('American Express')).must_equal false
  end
end

describe 'a scoped detector and the v9 legacy-plugin shim' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:visa)           { '4111111111111111' }

  # The shim fires at most once per brand and leaves a predicate method
  # behind that reload! does not undo, so reset both sides every time.
  before { reset_dankort }

  after do
    reset_dankort
    CreditCardValidations.reload!
  end

  def reset_dankort
    detector_class.delete_brand(:dankort)
  end

end
