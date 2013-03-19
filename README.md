# CreditCardValidations

Gem adds validator  to check whether or not a given number actually falls within the ranges of possible numbers prior to performing such verification, and, as such, CreditCardValidations simply verifies that the credit card number provided is well-formed.
This is a port of Zend Framework `Zend\Validator\CreditCard` .

The following issuing institutes are accepted:


    American Express
    China UnionPay
    Diners Club
    Dinner Club US
    Discover
    JCB
    Maestro
    MasterCard
    Solo
    Visa



Also You can add your own rules to detect other credit card brands/types
passing name,length(integer/array of integers) and prefix(string/array of strings)
Example

    CreditCardValidations::Detector.add_rule(:voyager, 15, '86')
  	voyager_test_card_number = '869926275400212'
    CreditCardValidations::Detector.new(voyager_test_card_number).brand #:voyager
    CreditCardValidations::Detector.new(voyager_test_card_number).voyager? #true
 


AvtiveModel support
	
only for certain brads	
	
	class CreditCardModel
  		attr_accessor :number
  		include ActiveModel::Validations
  		validates :number, presence: true, credit_card_number: {brands: [:amex, :maestro]}
	end
	
for all known brands
	
	validates :number, presence: true, credit_card_number: true

  



## Installation

Add this line to your application's Gemfile:

    gem 'credit_card_validations'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install credit_card_validations

## Usage



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
