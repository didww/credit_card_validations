# CreditCardValidations

Gem adds validator  to check whether or not a given number actually falls within the ranges of possible numbers prior to performing such verification, and, as such, CreditCardValidations simply verifies that the credit card number provided is well-formed.

[![Build Status](https://travis-ci.org/Fivell/credit_card_validations.png)](https://travis-ci.org/Fivell/credit_card_validations)
[![Coverage Status](https://coveralls.io/repos/Fivell/credit_card_validations/badge.png)](https://coveralls.io/r/Fivell/credit_card_validations)

## Installation

Add this line to your application's Gemfile:

    gem 'credit_card_validations'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install credit_card_validations

## Usage


The following issuing institutes are accepted:
    
    name             | key
    -----------------------
    American Express | :amex
    China UnionPay   | :unionpay
    Dankrot          | :dankrot
    Diners Club      | :diners
    Dinner Club US   | :diners_us
    Discover         | :discover
    JCB              | :jcb
    Laser            | :laser
    Maestro          | :maestro
    MasterCard       | :mastercard
    Solo             | :solo
    Visa             | :visa



Examples using string monkey patch

    require 'credit_card_validations/string'
    '5274 5763 9425 9961'.credit_card_brand
    '5274 5763 9425 9961'.valid_credit_card_brand?(:mastercard, :visa)  
    '5274 5763 9425 9961'.valid_credit_card_brand?(:amex)  


ActiveModel support

only for certain brads	

	class CreditCardModel
	  	attr_accessor :number
	  	include ActiveModel::Validations
	  	validates :number, credit_card_number: {brands: [:amex, :maestro]}
	end

for all known brands
	
	validates :number, presence: true, credit_card_number: true


Examples using CreditCardValidations::Detector class

    number = "4111111111111111"
    detector = CreditCardValidations::Detector.new(number)
    detector.brand #:visa
    detector.visa? #true
    detector.valid?(:mastercard,:maestro) #false
    detector.valid?(:visa, :mastercard) #true
    detector.issuer_category  #"Banking and financial"

Also You can add your own rules to detect other credit card brands/types
passing name,length(integer/array of integers) and prefix(string/array of strings)
Example

    CreditCardValidations.add_rule(:voyager, 15, '86')
    CreditCardValidations.add_rule(:en_route, 15, ['2014', '2149'], true) #skip luhn = true
          
    voyager_test_card_number = '869926275400212'
    CreditCardValidations::Detector.new(voyager_test_card_number).brand #:voyager
    CreditCardValidations::Detector.new(voyager_test_card_number).voyager? #true
    
    en_route_test_card_number = '2014-0000-0000-001'
    CreditCardValidations::Detector.new(en_route_test_card_number).brand #:en_route
    CreditCardValidations::Detector.new(en_route_test_card_number).en_route? #true

Check luhn

    CreditCardValidations::Detector.new(@credit_card_number).valid_luhn?
    #or
    CreditCardValidations::Luhn.valid?(@credit_card_number)
  


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request



