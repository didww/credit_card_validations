require_relative 'test_helper'

# Which brand wins when more than one claims the same PAN.
#
# The primary rule is the longest matched prefix, and it settles almost
# everything. What it cannot settle is an exact tie: two brands claiming the
# same prefix at the same number length. There the registry order decides, and
# the order is not arbitrary -- the eight default brands are always in the
# registry before any plugin, because a plugin cannot be required before the
# gem itself, and add_brand appends after both.
describe 'brand precedence' do
  let(:detector_class) { CreditCardValidations::Detector }

  after do
    %i[diners_us laser elo my_own rival].each { |brand| detector_class.delete_brand(brand) }
    CreditCardValidations.reload!
  end

  describe 'an exact tie between a default brand and a plugin' do
    # :diners_us claims the whole of 54/55 at 16 digits, which is also
    # MasterCard's. The two are equally specific, so the longest-prefix rule
    # cannot pick one. The card routes over MasterCard -- and of the
    # 19_678 BINs on 54/55 in a real BIN table, 19_671 are labelled MasterCard
    # and none is labelled Diners Club.
    it 'goes to the default brand, not the plugin' do
      load_plugin(:diners_us)

      expect(detector_class.new('5474874856735893').brand).must_equal :mastercard
    end

  end

  describe 'an explicit brand filter' do
    # Hash#slice returns keys in the order of its arguments, so slicing the
    # registry by the caller's list threw the registry order away and let the
    # argument order decide the tie instead.
    it 'does not let the argument order decide the tie' do
      load_plugin(:diners_us)
      pan = '5474874856735893'

      expect(detector_class.new(pan).brand).must_equal :mastercard
      expect(detector_class.new(pan).brand(:diners_us, :mastercard)).must_equal :mastercard
      expect(detector_class.new(pan).brand(:mastercard, :diners_us)).must_equal :mastercard
    end

    it 'still narrows to the brands it was given' do
      expect(detector_class.new('5274576394259961').brand(:visa)).must_be_nil
      expect(detector_class.new('5274576394259961').brand(:visa, :mastercard)).must_equal :mastercard
    end
  end

  describe 'a brand set built from an explicit list' do
    it 'does not let the argument order decide the tie either' do
      load_plugin(:diners_us)
      pan = '5474874856735893'

      expect(CreditCardValidations.with_brands(:diners_us, :mastercard).detect(pan).brand)
        .must_equal :mastercard
      expect(CreditCardValidations.with_brands(:mastercard, :diners_us).detect(pan).brand)
        .must_equal :mastercard
    end
  end

  describe 'prefixes of different length in one rule' do
    it 'matches the longest whatever order they are declared in' do
      # The longest is declared in the middle, so neither the declared order
      # nor its reverse puts it first: '8' would report one digit, '87' two,
      # and either loses to :rival's three.
      # :rival first, so a "first brand that matches wins" implementation
      # would answer with it and this example would notice.
      CreditCardValidations.add_brand(:rival, { length: 16, prefixes: '877' })
      CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: %w[8 8771 87] })

      expect(detector_class.new('8771890123456786').brand).must_equal :my_own
    end

    after { detector_class.delete_brand(:rival) }
  end

  describe 'a brand declaring the same length in two rules' do
    # add_brand takes a list of rules, and matches_brand? returned the first
    # rule that matched rather than the longest match across them, so an
    # earlier short prefix hid a later long one.
    it 'reports the longest match across all of them' do
      CreditCardValidations.add_brand(:my_own, [{ length: 16, prefixes: '8' },
                                                { length: 16, prefixes: '8771' }])
      CreditCardValidations.add_brand(:rival, { length: 16, prefixes: '87' })

      # :my_own declares 4 digits of this PAN and :rival only 2, but the short
      # rule comes first, so :my_own used to report 1 digit and lose.
      expect(detector_class.new('8771890123456786').brand).must_equal :my_own
    end

    after { detector_class.delete_brand(:rival) }
  end

  describe 'a length the brand does not declare' do
    it 'is not matched on prefix alone' do
      # Luhn-valid, Visa prefix, 14 digits; :visa declares 13, 16 and 19.
      expect(detector_class.new('40000000000002').brand).must_be_nil
      # Luhn-valid, Diners prefix, 16 digits; :diners declares 14.
      expect(detector_class.new('3000000000000004').brand).must_be_nil
    end
  end

  describe 'a brand key given per call' do
    it 'is accepted in any case, as a symbol or a string' do
      pan = '4111111111111111'

      expect(detector_class.new(pan).brand(:VISA)).must_equal :visa
      expect(detector_class.new(pan).brand('VISA')).must_equal :visa
    end
  end

  describe 'a prefix that looks like regexp syntax' do
    it 'counts as the literal digits it spells, not as a pattern' do
      CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: ['5474', '5[0-9]'] })
      pan = '5474874856735893'

      # '5[0-9]' is six characters but would match two. Ordering by the length
      # of the prefix only reports the longest match if a prefix matches
      # itself, so the pattern is escaped.
      expect(detector_class.brands[:my_own][:rules].first[:regexp].source)
        .must_equal '^((5\\[0\\-9\\])|(5474))'
      expect(detector_class.new(pan).brand).must_equal :my_own
    end

    it 'agrees with possible_brands, which compares prefixes as plain text' do
      CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: ['5[0-9]'] })

      expect(detector_class.new('5[0').possible_brands).must_equal [:my_own]
      expect(detector_class.new('5474874856735893').valid?(:my_own)).must_equal false
    end
  end

  describe 'a brand registered with an empty prefix' do
    it 'can still win when nothing more specific matches' do
      CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: '' })

      expect(detector_class.new('8771890123456786').brand).must_equal :my_own
    end

    it 'loses to any brand that declares a digit' do
      CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: '' })
      pan = '4111111111111111'

      # Both must hold: the brand matched, and it still lost.
      expect(detector_class.new(pan).valid?(:my_own)).must_equal true
      expect(detector_class.new(pan).brand).must_equal :visa
    end
  end

  describe 'a brand registered through add_brand' do
    it 'loses an exact tie with a default brand' do
      CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: '54' })

      expect(detector_class.new('5474874856735893').brand).must_equal :mastercard
    end

    it 'still wins on a longer prefix' do
      CreditCardValidations.add_brand(:my_own, { length: 16, prefixes: '5474' })

      expect(detector_class.new('5474874856735893').brand).must_equal :my_own
    end
  end

  describe 'a brand that declares both a short and a long prefix' do
    # Regexp alternation is first-match, left-to-right, not longest-match, so
    # ^((677)|(6771)) matches "677" against a 6771... PAN. The brand then
    # reports a 3-digit match for a prefix it declares 4 digits of, and loses
    # a comparison it should win. :maestro, :carnet and :elo all declare such
    # pairs -- 17 prefixes in total are unreachable as the longest match.
    it 'matches on the longest one it declares, not the first' do
      rule = detector_class.brands[:maestro][:rules].first
      expect(rule[:prefixes]).must_include '677'
      expect(rule[:prefixes]).must_include '6771'

      expect('6771890123456780'.match(rule[:regexp]).to_s).must_equal '6771'
    end

    it 'does not lose a PAN to a plugin that declares the long prefix alone' do
      load_plugin(:laser)

      # :laser declares 6771 and nothing shorter, so under-reporting put a
      # default brand behind a plugin without any tie being involved.
      expect(detector_class.new('6771890123456780').brand).must_equal :maestro
    end
  end

  describe 'a longer prefix' do
    # :elo is a plugin and claims 401178, inside Visa's 4. Order does not come
    # into it: six digits beat one, so the plugin wins. Precedence by order is
    # the tie-break, not the rule.
    it 'wins for a plugin over a default brand' do
      load_plugin(:elo)

      expect(detector_class.new('4011789012345671').brand).must_equal :elo
      expect(detector_class.new('4111111111111111').brand).must_equal :visa
    end

  end
end
