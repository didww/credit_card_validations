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
    %i[diners_us laser my_own].each { |brand| detector_class.delete_brand(brand) }
    CreditCardValidations.reload!
  end

  describe 'an exact tie between a default brand and a plugin' do
    # :diners_us claims the whole of 54/55 at 16 digits, which is also
    # MasterCard's. The two are equally specific, so the longest-prefix rule
    # cannot pick one. The card routes over MasterCard -- and of the 19_671
    # BINs on 54/55 in a real BIN table, every one is labelled MasterCard.
    it 'goes to the default brand, not the plugin' do
      load 'credit_card_validations/plugins/diners_us.rb'

      expect(detector_class.new('5474874856735893').brand).must_equal :mastercard
    end

    it 'is stable across repeated calls' do
      load 'credit_card_validations/plugins/diners_us.rb'

      answers = Array.new(50) { detector_class.new('5474874856735893').brand }.uniq

      expect(answers).must_equal [:mastercard]
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

  describe 'a longer prefix' do
    # :elo is a plugin and claims 401178, inside Visa's 4. Order does not come
    # into it: six digits beat one, so the plugin wins. Precedence by order is
    # the tie-break, not the rule.
    it 'wins for a plugin over a default brand' do
      load 'credit_card_validations/plugins/elo.rb'

      expect(detector_class.new('4011789012345671').brand).must_equal :elo
      expect(detector_class.new('4111111111111111').brand).must_equal :visa
    end

    after { detector_class.delete_brand(:elo) }
  end
end
