# CreditCardValidations

[![Build Status](http://img.shields.io/travis/Fivell/credit_card_validations.svg)](https://travis-ci.org/Fivell/credit_card_validations)
[![Dependency Status](http://img.shields.io/gemnasium/Fivell/credit_card_validations.svg)](https://gemnasium.com/Fivell/credit_card_validations)
[![Coverage Status](http://img.shields.io/coveralls/Fivell/credit_card_validations.svg)](https://coveralls.io/r/Fivell/credit_card_validations)
[![Code Climate](http://img.shields.io/codeclimate/github/Fivell/credit_card_validations.svg)](https://codeclimate.com/github/Fivell/credit_card_validations)
[![Gem Version](http://img.shields.io/gem/v/credit_card_validations.svg)](https://rubygems.org/gems/credit_card_validations)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://Fivell.mit-license.org)


Gem adds validator  to check whether or not a given number actually falls within the ranges of possible numbers prior to performing such verification, and, as such, CreditCardValidations simply verifies that the credit card number provided is well-formed.

More info about card BIN numbers http://en.wikipedia.org/wiki/Bank_card_number

## Installation

Add this line to your application's Gemfile:

    gem 'credit_card_validations'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install credit_card_validations

## Usage


The following issuing institutes are accepted:
    
    name             | key          |
    -------------------------------------------------------------------
    American Express | :amex        | http://en.wikipedia.org/wiki/American_Express
    China UnionPay   | :unionpay    | http://en.wikipedia.org/wiki/China_UnionPay
    Dankrot          | :dankrot     | http://en.wikipedia.org/wiki/Dankort
    Diners Club      | :diners      | http://en.wikipedia.org/wiki/Diners_Club_International
    Dinner Club US   | :diners_us   | http://en.wikipedia.org/wiki/Diners_Club_International#MasterCard_alliance
    Discover         | :discover    | http://en.wikipedia.org/wiki/Discover_Card
    Hipercard        | :hipercard   | http://pt.wikipedia.org/wiki/Hipercard
    JCB              | :jcb         | http://en.wikipedia.org/wiki/Japan_Credit_Bureau
    Laser            | :laser       | http://en.wikipedia.org/wiki/Laser_%28debit_card%29
    Maestro          | :maestro     | http://en.wikipedia.org/wiki/Maestro_%28debit_card%29
    MasterCard       | :mastercard  | http://en.wikipedia.org/wiki/MasterCard
    Rupay            | :rupay       | http://en.wikipedia.org/wiki/RuPay
    Solo             | :solo        | http://en.wikipedia.org/wiki/Solo_(debit_card)
    Switch           | :switch      | http://en.wikipedia.org/wiki/Switch_(debit_card)
    Visa             | :visa        | http://en.wikipedia.org/wiki/Visa_Inc.



Examples using string monkey patch

```ruby
    require 'credit_card_validations/string'
    '5274 5763 9425 9961'.credit_card_brand   #=> :mastercard
    '5274 5763 9425 9961'.credit_card_brand_name   #=> "MasterCard"
    '5274 5763 9425 9961'.valid_credit_card_brand?(:mastercard, :visa) #=> true
    '5274 5763 9425 9961'.valid_credit_card_brand?(:amex) #=> false
    '5274 5763 9425 9961'.valid_credit_card_brand?('MasterCard') #=> true
```

ActiveModel support

only for certain brads

```ruby
    class CreditCardModel 
        attr_accessor :number
        include ActiveModel::Validations
        validates :number, credit_card_number: {brands: [:amex, :maestro]} 
    end
```

for all known brands

```ruby	
    validates :number, presence: true, credit_card_number: true
```

Examples using CreditCardValidations::Detector class

```ruby	
    number = "4111111111111111"
    detector = CreditCardValidations::Detector.new(number)
    detector.brand #:visa
    detector.visa? #true
    detector.valid?(:mastercard,:maestro) #false
    detector.valid?(:visa, :mastercard) #true
    detector.issuer_category  #"Banking and financial"
```

Also You can add your own brand rules to detect other credit card brands/types
passing name,length(integer/array of integers) and prefix(string/array of strings)
Example

```ruby	
    CreditCardValidations.add_brand(:voyager, {length: 15, prefixes: '86'})
    CreditCardValidations.add_brand(:en_route, {length: 15, prefixes: ['2014', '2149']}, {skip_luhn: true}) #skip luhn
          
    voyager_test_card_number = '869926275400212'
    CreditCardValidations::Detector.new(voyager_test_card_number).brand #:voyager
    CreditCardValidations::Detector.new(voyager_test_card_number).voyager? #true
    
    en_route_test_card_number = '2014-0000-0000-001'
    CreditCardValidations::Detector.new(en_route_test_card_number).brand #:en_route
    CreditCardValidations::Detector.new(en_route_test_card_number).en_route? #true
```

Remove brands also supported

```ruby
    CreditCardValidations.delete_brand(:maestro)
```



Check luhn

```ruby	
    CreditCardValidations::Detector.new(@credit_card_number).valid_luhn?
    #or
    CreditCardValidations::Luhn.valid?(@credit_card_number)
```  

Generate credit card numbers that pass validation

```ruby
 CreditCardValidations::Factory.random(:amex)
 # => "348051773827666"
 CreditCardValidations::Factory.random(:maestro)
 # => "6010430241237266856"
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request



