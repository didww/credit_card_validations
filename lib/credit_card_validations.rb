require 'credit_card_validations/version'
require 'active_model'
require 'active_support/all'
require 'active_model/validations'
require 'credit_card_number_validator'

module CreditCardValidations
   extend ActiveSupport::Autoload
   autoload :VERSION, 'credit_card_validations/version'
   autoload :Luhn, 'credit_card_validations/luhn'
   autoload :CardRules , 'credit_card_validations/card_rules'
   autoload :Detector , 'credit_card_validations/detector'
end  
