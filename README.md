# CreditCardValidations

[![Gem Version](http://img.shields.io/gem/v/credit_card_validations.svg)](https://rubygems.org/gems/credit_card_validations)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://didww.mit-license.org)
![Coverage](https://didww.github.io/credit_card_validations/badge.svg)


Gem adds validator  to check whether or not a given number actually falls within the ranges of possible numbers prior to performing such verification, and, as such, CreditCardValidations simply verifies that the credit card number provided is well-formed.

More info about card BIN numbers http://en.wikipedia.org/wiki/Bank_card_number

## Installation

Add this line to your application's Gemfile:

```sh
$ gem 'credit_card_validations'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install credit_card_validations
```

## Usage


The following issuing institutes are accepted:
    
|    Name   |    Key     | 
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



The following are supported with plugins

|    Name   |    Key     |
---------------------   | ------------|
[Cabal](https://en.wikipedia.org/wiki/Cabal_(debit_card)) | :cabal
[Carnet](https://en.wikipedia.org/wiki/Carnet_(card)) | :carnet
[Cartes Bancaires](https://en.wikipedia.org/wiki/Cartes_Bancaires) | :cartes_bancaires
[DinaCard](https://en.wikipedia.org/wiki/DinaCard) | :dinacard
[Diners Club US](http://en.wikipedia.org/wiki/Diners_Club_International#MasterCard_alliance)  | :diners_us
[EnRoute](https://en.wikipedia.org/wiki/EnRoute_(credit_card)) | :en_route
[Girocard](https://en.wikipedia.org/wiki/Girocard) | :girocard
[Hiper](https://en.wikipedia.org/wiki/Itau_Unibanco) | :hiper
[Humo](https://en.wikipedia.org/wiki/Humo_(payment_system)) | :humocard
[Laser](https://en.wikipedia.org/wiki/Laser_%28debit_card%29)      | :laser
[Mada](https://en.wikipedia.org/wiki/Mada_(payment_system)) | :mada
[Naranja](https://en.wikipedia.org/wiki/Tarjeta_Naranja) | :naranja
[Troy](https://en.wikipedia.org/wiki/Troy_(payment_system)) | :troy
[UATP](https://en.wikipedia.org/wiki/Universal_Air_Travel_Plan) | :uatp
[Uzcard](https://en.wikipedia.org/wiki/Uzcard) | :uzcard
[V Pay](https://en.wikipedia.org/wiki/V_Pay) | :vpay
[Verve](https://en.wikipedia.org/wiki/Verve_(payment_card)) | :verve
[Voyager](https://en.wikipedia.org/wiki/Voyager_card) | :voyager



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

### CVV and Expiration validators

CVV against a brand pulled from another attribute:

```ruby
class Payment
  include ActiveModel::Validations
  attr_accessor :card_number, :cvv

  validates :card_number, credit_card_number: true
  validates :cvv,         credit_card_cvv: { brand_from: :card_number }
end
```

CVV against a literal brand:

```ruby
validates :cvv, credit_card_cvv: { brand: :amex }
```

Expiration held in a single string attribute (`MM/YY`, `MM/YYYY`, `MMYY`, ...):

```ruby
validates :expiration, credit_card_expiration: true
```

When the form uses two separate fields (month and year dropdowns), use the
`Expiration` class directly in a `validate` block:

```ruby
class Payment
  attr_accessor :exp_month, :exp_year

  validate do
    exp = CreditCardValidations::Expiration.new(exp_month, exp_year)
    errors.add(:exp_month, :invalid) unless exp.valid?
  end
end
```

### CreditCardValidations::Card

A composite model wrapping `Detector` and `Expiration` behind a single
ActiveModel-aware object:

```ruby
card = CreditCardValidations::Card.new(
  number: '4111 1111 1111 1111',
  month: 12, year: 2027,
  verification_value: '123',
  name: 'John Smith'
)
card.valid?            # => true
card.brand             # => :visa
card.display_number    # => "************1111"
card.last_digits       # => "1111"
card.expired?          # => false
card.formatted_number  # => "4111 1111 1111 1111"
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

require 'credit_card_validations/plugins/cabal'
require 'credit_card_validations/plugins/carnet'
require 'credit_card_validations/plugins/cartes_bancaires'
require 'credit_card_validations/plugins/dinacard'
require 'credit_card_validations/plugins/girocard'
require 'credit_card_validations/plugins/hiper'
require 'credit_card_validations/plugins/humocard'
require 'credit_card_validations/plugins/mada'
require 'credit_card_validations/plugins/naranja'
require 'credit_card_validations/plugins/troy'
require 'credit_card_validations/plugins/uatp'
require 'credit_card_validations/plugins/uzcard'
require 'credit_card_validations/plugins/verve'
require 'credit_card_validations/plugins/voyager'
require 'credit_card_validations/plugins/vpay'
```


### Configuration

In order to override default data source you can copy [original one](https://github.com/didww/credit_card_validations/blob/master/lib/data/brands.yaml) , change it and configure during rails initializer

```ruby
 CreditCardValidations.configure do |config|
      config.source = '/path/to/my_brands.yml'
 end
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request



