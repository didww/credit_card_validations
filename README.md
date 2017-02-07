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
    
    Name   |    Key     | 
---------------------   | ------------| 
[American Express](http://en.wikipedia.org/wiki/American_Express) | :amex
[China UnionPay](http://en.wikipedia.org/wiki/China_UnionPay)    | :unionpay 
[Dankort](http://en.wikipedia.org/wiki/Dankort)      | :dankort
[Diners Club](http://en.wikipedia.org/wiki/Diners_Club_International)  | :diners   
[Elo](https://pt.wikipedia.org/wiki/Elo_Participa%C3%A7%C3%B5es_S/A)      | :elo
[Discover](http://en.wikipedia.org/wiki/Discover_Card) | :discover   
[Hipercard](http://pt.wikipedia.org/wiki/Hipercard) | :hipercard  
[JCB](http://en.wikipedia.org/wiki/Japan_Credit_Bureau)  | :jcb
[Maestro](http://en.wikipedia.org/wiki/Maestro_%28debit_card%29)    | :maestro
[MasterCard](http://en.wikipedia.org/wiki/MasterCard)  |   :mastercard
[MIR](http://www.nspk.ru/en/cards-mir/)  |   :mir
[Rupay](http://en.wikipedia.org/wiki/RuPay) |   :rupay 
[Solo](http://en.wikipedia.org/wiki/Solo_(debit_card))     | :solo
[Switch](http://en.wikipedia.org/wiki/Switch_(debit_card)) | :switch 
[Visa](http://en.wikipedia.org/wiki/Visa_Inc.)      | :visa  



The following are supported with with plugins

    Name   |    Key     | 
---------------------   | ------------| 
[Diners Club US](http://en.wikipedia.org/wiki/Diners_Club_International#MasterCard_alliance)  | :diners_us  
[EnRoute](https://en.wikipedia.org/wiki/EnRoute_(credit_card)) | :en_route
[Laser](https://en.wikipedia.org/wiki/Laser_%28debit_card%29)      | :laser



### Examples using string monkey patch

```ruby
    require 'credit_card_validations/string'
    '5274 5763 9425 9961'.credit_card_brand   #=> :mastercard
    '5274 5763 9425 9961'.credit_card_brand_name   #=> "MasterCard"
    '5274 5763 9425 9961'.valid_credit_card_brand?(:mastercard, :visa) #=> true
    '5274 5763 9425 9961'.valid_credit_card_brand?(:amex) #=> false
    '5274 5763 9425 9961'.valid_credit_card_brand?('MasterCard') #=> true
```

### ActiveModel support

only for certain brands

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

### Examples using CreditCardValidations::Detector class

```ruby	
    number = "4111111111111111"
    detector = CreditCardValidations::Detector.new(number)
    detector.brand #:visa
    detector.visa? #true
    detector.valid?(:mastercard,:maestro) #false
    detector.valid?(:visa, :mastercard) #true
    detector.issuer_category  #"Banking and financial"
```

### Also You can add your own brand rules to detect other credit card brands/types
passing name,length(integer/array of integers) and prefix(string/array of strings)
Example

```ruby	
    CreditCardValidations.add_brand(:voyager, {length: 15, prefixes: '86'})
    voyager_test_card_number = '869926275400212'
    CreditCardValidations::Detector.new(voyager_test_card_number).brand #:voyager
    CreditCardValidations::Detector.new(voyager_test_card_number).voyager? #true
```

### Remove brands also supported

```ruby
    CreditCardValidations::Detector.delete_brand(:maestro)
```

### Check luhn

```ruby	
    CreditCardValidations::Detector.new(@credit_card_number).valid_luhn?
    #or
    CreditCardValidations::Luhn.valid?(@credit_card_number)
```  

### Generate credit card numbers that pass validation

```ruby
 CreditCardValidations::Factory.random(:amex)
 # => "348051773827666"
 CreditCardValidations::Factory.random(:maestro)
 # => "6010430241237266856"
```

### Plugins 

  ```ruby 
  require 'credit_card_validations/plugins/en_route'
  require 'credit_card_validations/plugins/laser'
  require 'credit_card_validations/plugins/diners_us'

  ```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request



