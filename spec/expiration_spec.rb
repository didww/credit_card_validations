require_relative 'test_helper'
require 'date'

describe CreditCardValidations::Expiration do
  Expiration = CreditCardValidations::Expiration

  describe '.parse' do
    it 'parses MM/YY' do
      exp = Expiration.parse('09/27')
      expect(exp.month).must_equal 9
      expect(exp.year).must_equal 2027
    end

    it 'parses MM/YYYY' do
      exp = Expiration.parse('09/2027')
      expect(exp.month).must_equal 9
      expect(exp.year).must_equal 2027
    end

    it 'parses MM-YY and MMYY' do
      expect(Expiration.parse('09-27').year).must_equal 2027
      expect(Expiration.parse('0927').year).must_equal 2027
    end

    it 'tolerates surrounding whitespace' do
      expect(Expiration.parse('  09 / 27 ').year).must_equal 2027
    end

    it 'returns nil for unparseable input' do
      expect(Expiration.parse(nil)).must_be_nil
      expect(Expiration.parse('')).must_be_nil
      expect(Expiration.parse('garbage')).must_be_nil
      expect(Expiration.parse('13/27')).must_be_nil
      expect(Expiration.parse('00/27')).must_be_nil
    end
  end

  describe '#valid? and #expired?' do
    it 'is valid for a future date' do
      future = Date.today.next_year
      exp = Expiration.new(future.month, future.year)
      expect(exp.valid?).must_equal true
      expect(exp.expired?).must_equal false
    end

    it 'is valid on the last day of the expiration month' do
      today = Date.new(2026, 6, 15)
      exp = Expiration.new(6, 2026)
      expect(exp.expired?(today)).must_equal false
    end

    it 'is expired the day after the last day of the month' do
      exp = Expiration.new(5, 2026)
      expect(exp.expired?(Date.new(2026, 6, 1))).must_equal true
    end

    it 'handles leap-year February correctly' do
      exp = Expiration.new(2, 2028) # 2028 is leap
      expect(exp.expired?(Date.new(2028, 2, 29))).must_equal false
      expect(exp.expired?(Date.new(2028, 3, 1))).must_equal true
    end

    it 'returns false from #valid? without raising on month 0/13' do
      expect(Expiration.new(0, 2027).valid?).must_equal false
      expect(Expiration.new(13, 2027).valid?).must_equal false
      expect(Expiration.new(13, 2027).expired?).must_equal true
    end

    it 'returns false from #valid? on missing year' do
      expect(Expiration.new(6, nil).valid?).must_equal false
    end
  end

  describe '#last_day' do
    it 'returns the last day of the month for valid inputs' do
      expect(Expiration.new(2, 2027).last_day).must_equal Date.new(2027, 2, 28)
      expect(Expiration.new(2, 2028).last_day).must_equal Date.new(2028, 2, 29)
      expect(Expiration.new(12, 2027).last_day).must_equal Date.new(2027, 12, 31)
    end

    it 'returns nil for invalid month' do
      expect(Expiration.new(13, 2027).last_day).must_be_nil
    end
  end
end
