require 'date'

# == CreditCardValidations Expiration
# Slim parser+validator for card expiration dates.
#
#   exp = CreditCardValidations::Expiration.parse('09/27')
#   exp.valid?              # => true
#   exp.expired?            # => false
#   exp.last_day            # => Date.new(2027, 9, 30)
#
# A card is valid through the *last day* of its expiration month, matching
# how issuers and networks interpret it.
#
module CreditCardValidations
  class Expiration
    FORMATS = ['%m/%Y', '%m/%y', '%m-%Y', '%m-%y', '%m%Y', '%m%y'].freeze

    attr_reader :month, :year

    def initialize(month, year)
      @month = month.to_i if month
      @year = normalize_year(year.to_i) if year
    end

    def self.parse(raw)
      stripped = raw.to_s.gsub(/\s+/, '')
      return nil if stripped.empty?
      FORMATS.each do |fmt|
        date = begin
          Date.strptime(stripped, fmt)
        rescue Date::Error
          nil
        end
        return new(date.month, date.year) if date
      end
      nil
    end

    def valid?
      !expired?
    rescue Date::Error
      false
    end

    def expired?(today = Date.today)
      day = last_day
      day.nil? || today > day
    end

    def last_day
      return nil unless month && year && (1..12).cover?(month)
      Date.new(year, month, -1)
    rescue Date::Error
      nil
    end

    private

    def normalize_year(value)
      value < 100 ? 2000 + value : value
    end
  end
end
