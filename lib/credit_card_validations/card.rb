require 'active_model'

# == CreditCardValidations::Card
#
# Slim alternative to ActiveMerchant::Billing::CreditCard for the validation
# use case. Wraps PAN, expiration, verification value and cardholder name
# behind a single ActiveModel-aware object.
#
#   card = CreditCardValidations::Card.new(
#     number: '4111 1111 1111 1111',
#     month: 12, year: 2027,
#     verification_value: '123',
#     name: 'John Smith'
#   )
#   card.valid?            # => true
#   card.brand             # => :visa
#   card.display_number    # => "************1111"
#   card.last_digits       # => "1111"
#   card.expired?          # => false
#   card.formatted_number  # => "4111 1111 1111 1111"
#
module CreditCardValidations
  class Card
    include ActiveModel::Model

    attr_accessor :number, :month, :year, :verification_value, :name

    validates :number, credit_card_number: true
    validates :verification_value, credit_card_cvv: { brand_from: :number }
    validate :expiration_must_be_valid

    def brand              = detector.brand
    def brand_name         = detector.brand_name
    def last_digits        = detector.last4
    def display_number     = detector.masked
    def formatted_number   = detector.formatted

    def expiration
      return nil unless month && year
      Expiration.new(month, year)
    end

    def expired?
      exp = expiration
      exp.nil? || exp.expired?
    end

    def detector
      @detector ||= Detector.new(number)
    end

    private

    def expiration_must_be_valid
      return if month.blank? && year.blank?
      exp = expiration
      errors.add(:base, :expired) if exp && exp.expired?
      errors.add(:month, :invalid) if exp && !(1..12).cover?(exp.month)
    end
  end
end
