# CreditCardValidations

[![Gem Version](http://img.shields.io/gem/v/credit_card_validations.svg)](https://rubygems.org/gems/credit_card_validations)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://didww.mit-license.org)
![Coverage](https://didww.github.io/credit_card_validations/badge.svg)


Gem adds a validator to check whether a given number actually falls within the ranges of possible numbers prior to performing verification — `CreditCardValidations` verifies that the credit card number provided is well-formed.

More info about card BIN numbers: http://en.wikipedia.org/wiki/Bank_card_number

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

## Default brands

These brands are detected out of the box. They are the international majors that most acquirers, gateways, and payment forms care about:

|    Name   |    Key     |
---------------------   | ------------|
[American Express](http://en.wikipedia.org/wiki/American_Express) | `:amex`
[China UnionPay](http://en.wikipedia.org/wiki/China_UnionPay) | `:unionpay`
[Diners Club](http://en.wikipedia.org/wiki/Diners_Club_International) | `:diners`
[Discover](http://en.wikipedia.org/wiki/Discover_Card) | `:discover`
[JCB](http://en.wikipedia.org/wiki/Japan_Credit_Bureau) | `:jcb`
[Maestro](http://en.wikipedia.org/wiki/Maestro_%28debit_card%29) | `:maestro`
[MasterCard](http://en.wikipedia.org/wiki/MasterCard) | `:mastercard`
[Visa](http://en.wikipedia.org/wiki/Visa_Inc.) | `:visa`

## Opt-in plugins

Everything else is detected only when its plugin is explicitly required. Plugins add no startup cost, no API surface, and no chance of misdetection to apps that don't accept the brand.

### Active regional and specialty networks

|    Name   |    Key     |
---------------------   | ------------|
[Cabal](https://en.wikipedia.org/wiki/Cabal_(debit_card)) | `:cabal`
[Carnet](https://en.wikipedia.org/wiki/Carnet_(card)) | `:carnet`
[Cartes Bancaires](https://en.wikipedia.org/wiki/Cartes_Bancaires) | `:cartes_bancaires`
[Dankort](http://en.wikipedia.org/wiki/Dankort) | `:dankort`
[DinaCard](https://en.wikipedia.org/wiki/DinaCard) | `:dinacard`
[Elo](https://pt.wikipedia.org/wiki/Elo_Participa%C3%A7%C3%B5es_S/A) | `:elo`
[Girocard](https://en.wikipedia.org/wiki/Girocard) | `:girocard`
[Hiper](https://en.wikipedia.org/wiki/Itau_Unibanco) | `:hiper`
[Hipercard](http://pt.wikipedia.org/wiki/Hipercard) | `:hipercard`
[Humo](https://en.wikipedia.org/wiki/Humo_(payment_system)) | `:humocard`
[Mada](https://en.wikipedia.org/wiki/Mada_(payment_system)) | `:mada`
[MIR](http://www.nspk.ru/en/cards-mir/) | `:mir`
[Naranja](https://en.wikipedia.org/wiki/Tarjeta_Naranja) | `:naranja`
[RuPay](http://en.wikipedia.org/wiki/RuPay) | `:rupay`
[Troy](https://en.wikipedia.org/wiki/Troy_(payment_system)) | `:troy`
[UATP](https://en.wikipedia.org/wiki/Universal_Air_Travel_Plan) | `:uatp`
[Uzcard](https://en.wikipedia.org/wiki/Uzcard) | `:uzcard`
[V Pay](https://en.wikipedia.org/wiki/V_Pay) | `:vpay`
[Verve](https://en.wikipedia.org/wiki/Verve_(payment_card)) | `:verve`
[Voyager](https://en.wikipedia.org/wiki/Voyager_card) | `:voyager`

### Legacy / withdrawn networks

|    Name   |    Key     | Status |
---------------------   | ------------| ------|
[Diners Club US](http://en.wikipedia.org/wiki/Diners_Club_International#MasterCard_alliance) | `:diners_us` | Merged into Discover for US routing in 2008 |
[EnRoute](https://en.wikipedia.org/wiki/EnRoute_(credit_card)) | `:en_route` | Withdrawn 1989 |
[Laser](https://en.wikipedia.org/wiki/Laser_%28debit_card%29) | `:laser` | Withdrawn 2014 |
[Solo](https://en.wikipedia.org/wiki/Solo_(debit_card)) | `:solo` | Withdrawn 2011 |
[Switch](https://en.wikipedia.org/wiki/Switch_(debit_card)) | `:switch` | Withdrawn 2002 |

### Loading plugins

```ruby
# in an initializer or before first use
require 'credit_card_validations/plugins/mir'
require 'credit_card_validations/plugins/elo'
require 'credit_card_validations/plugins/hipercard'
# ... whichever brands the app actually accepts
```

## Migrating from v9.x → v10.0 (unreleased)

On `master`, ahead of the v10.0 release, the auto-require shim is gone. In v9.0 the seven brands below moved out of the
default set, and referencing one of them still worked — the plugin was loaded
for you and a deprecation warning was printed once. v10.0 removes that.

If your code names any of these brands, add the matching `require`:

```ruby
# config/initializers/credit_card_validations.rb
require 'credit_card_validations/plugins/mir'
require 'credit_card_validations/plugins/elo'
# ... whichever brands the app actually accepts
```

Without it the brand is simply unknown. **Nothing warns** — the v9 deprecation
warning is gone too — and the read-only paths stay quiet, so a missing
`require` will not announce itself where you are most likely to notice it:

```ruby
Detector.new('2202 1234 1234 1234').brand                #=> nil
Detector.new('2202 1234 1234 1234').valid?(:mir)         #=> false
Detector.new('2202 1234 1234 1234').brand_name           #=> nil
Detector.new('2202 1234 1234 1234').possible_brands      #=> []
Detector.brand_name(:mir)                                #=> nil
Detector.valid_cvv?('123', :mir)                         #=> false
Detector.has_luhn_check_rule?(:mir)                      #=> true  (nothing opted out)
'2202 1234 1234 1234'.credit_card_brand                  #=> nil
'2202 1234 1234 1234'.credit_card_brand_name             #=> nil
'2202 1234 1234 1234'.valid_credit_card_brand?(:mir)     #=> false
```

Four paths do raise, because there is nothing sensible to return:

```ruby
Detector.new(pan).mir?                  # NoMethodError — the predicate is never defined
CreditCardValidations::Factory.random(:mir)   # CreditCardValidations::Error: Unsupported brand
Detector.add_rule(:mir, 16, ['2202'])         # CreditCardValidations::Error: brand mir is undefined
Detector::LEGACY_PLUGIN_BRANDS                # NameError — see below
```

ActiveModel validators never raise on a missing plugin; the record is just
invalid. Which means a PAN field restricted to a plugin brand **rejects every
number you give it**, including a valid card of that brand:

```ruby
validates :number, credit_card_number: { brands: [:mir] }   # nothing passes
validates :cvv,    credit_card_cvv:    { brand: :mir }      # nothing passes
```

`Detector::LEGACY_PLUGIN_BRANDS` was a public constant in v9 and is gone. An
app that read it to build its own require list now gets `NameError`; replace it
with a literal list of the brands you accept.

So check the brand list against your initializer rather than waiting for an
error — in the paths an app exercises most, there will not be one.

| Brand | Status |
|---|---|
| `:dankort` | Active (Denmark) |
| `:elo` | Active (Brazil) |
| `:hipercard` | Active (Brazil) |
| `:mir` | Active (Russia) |
| `:rupay` | Active (India) |
| `:solo` | Withdrawn 2011 |
| `:switch` | Withdrawn 2002 |

## Migrating from v8.x → v9.0

Seven brands moved from the default brand set to opt-in plugins in v9.0. Up to
v9.x an auto-require shim kept existing code working with a one-time
deprecation warning per brand; it is removed on master for v10.0, see above.

### Other breaking changes in v9.0

- **`Hipercard` cleaned up.** Length changed from 19 to 16 (which is the issued length); legacy `637*` prefixes that actually belong to Hiper were dropped. If you used Hipercard before, your detection now matches the brand's real spec.
- **`Discover` cleaned up.** Diners-only prefixes (`300-305, 3095, 36, 38, 39`) were dropped from Discover. Diners cards now correctly detect as `:diners` instead of `:discover`. Apps that branched on `:discover` for routing should branch on `[:diners, :discover]`.
- **`Luhn.valid?` is now strict.** It accepts a digit-only string and returns `false` for `nil`, empty input, or any non-digit character. User-facing input handling moved into `Detector#initialize`, which strips whitespace and dashes before delegating.
- **Brand YAML is loaded via `YAML.safe_load_file`.** Custom brand sources may need to declare `permitted_classes: [Symbol]` if they relied on extra Ruby objects.

## Usage

### String monkey patch

```ruby
require 'credit_card_validations/string'
'5274 5763 9425 9961'.credit_card_brand                                #=> :mastercard
'5274 5763 9425 9961'.credit_card_brand_name                           #=> "MasterCard"
'5274 5763 9425 9961'.valid_credit_card_brand?(:mastercard, :visa)     #=> true
'5274 5763 9425 9961'.valid_credit_card_brand?(:amex)                  #=> false
'5274 5763 9425 9961'.valid_credit_card_brand?('MasterCard')           #=> true
```

### ActiveModel validators

Restrict to a brand list:

```ruby
class CreditCardModel
  attr_accessor :number
  include ActiveModel::Validations
  validates :number, credit_card_number: { brands: [:amex, :maestro] }
end
```

Accept any known brand:

```ruby
validates :number, presence: true, credit_card_number: true
```

### CVV validator

CVV against a brand pulled from another attribute (the PAN):

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

### Expiration validator

A single string attribute (`MM/YY`, `MM/YYYY`, `MMYY`, ...):

```ruby
validates :expiration, credit_card_expiration: true
```

Two separate fields (typical month + year dropdowns) — use the `Expiration` class in a `validate` block:

```ruby
class Payment
  attr_accessor :exp_month, :exp_year

  validate do
    exp = CreditCardValidations::Expiration.new(exp_month, exp_year)
    errors.add(:exp_month, :invalid) unless exp.valid?
  end
end
```

### `CreditCardValidations::Card`

A composite model wrapping `Detector` and `Expiration` behind a single ActiveModel-aware object:

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

### Using `Detector` directly

```ruby
number   = '4111111111111111'
detector = CreditCardValidations::Detector.new(number)

detector.brand                          # => :visa
detector.visa?                          # => true
detector.valid?(:mastercard, :maestro)  # => false
detector.valid?(:visa, :mastercard)     # => true
detector.issuer_category                # => "Banking and financial"
detector.last4                          # => "1111"
detector.masked                         # => "************1111"
detector.formatted                      # => "4111 1111 1111 1111"
detector.possible_brands                # => [:visa]   (during live input)
detector.valid_cvv?('123')              # => true
```

### Detecting against a fixed brand list

`#valid?` and `#brand` take a brand list per call. `with_brands` holds that
list instead, and applies it to the methods that take no brand list of their
own — `possible_brands`, `brand_name`, `formatted`, `valid_cvv?`:

```ruby
set = CreditCardValidations.with_brands(:visa, :mastercard)

set.brands                                 # => [:visa, :mastercard]
set.detect('4111111111111111').brand       # => :visa
set.detect('348051773827666').brand        # => nil
set.detect('348051773827666').valid?       # => false
set.detect('34').possible_brands           # => []
```

`detect` returns a `Detector`, so the whole instance API works on it.

Keys are brand keys, as symbols or strings, in any case. An unknown key raises
`CreditCardValidations::Error` rather than being dropped, since a dropped brand
would mean a valid card is quietly rejected; an empty list raises for the same
reason.

A set narrows which brands are considered, not what they are — definitions
are read from `Detector.brands` at every lookup, so `add_brand`, `add_rule`,
`delete_brand` and a replaced brand source all apply to an existing set.

Which predicate methods exist stays global: `add_brand` defines them on
`Detector`, so a detector from a visa-only set still responds to
`mastercard?` (with `false`), and `delete_brand(:mastercard)` undefines it
everywhere. Use `valid?(:mastercard)` where that matters.

### Adding a custom brand at runtime

```ruby
CreditCardValidations.add_brand(:voyager, { length: 15, prefixes: '86' })
CreditCardValidations::Detector.new('869926275400212').voyager?  # => true
```

### Removing a brand at runtime

```ruby
CreditCardValidations::Detector.delete_brand(:maestro)
```

### Luhn check

```ruby
CreditCardValidations::Detector.new(number).valid_luhn?
# or, on a clean digit string:
CreditCardValidations::Luhn.valid?(number)
```

### Generating Luhn-valid test numbers

```ruby
CreditCardValidations::Factory.random(:amex)
# => "348051773827666"
CreditCardValidations::Factory.random(:maestro)
# => "6010430241237266856"
```

## Configuration

To override the default brand source, copy [the bundled `brands.yaml`](https://github.com/didww/credit_card_validations/blob/master/lib/data/brands.yaml), edit it, and point the gem at it in a Rails initializer:

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
5. Open a Pull Request
