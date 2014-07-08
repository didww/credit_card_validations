require 'credit_card_validations/version'
require 'active_model'
require 'active_support/core_ext'
require 'active_model/validations'
require 'active_model/credit_card_number_validator'

module CreditCardValidations
   extend ActiveSupport::Autoload
   autoload :VERSION, 'credit_card_validations/version'
   autoload :Luhn, 'credit_card_validations/luhn'
   autoload :CardRules , 'credit_card_validations/card_rules'
   autoload :Detector , 'credit_card_validations/detector'
   autoload :Mmi, 'credit_card_validations/mmi'
end  


CreditCardValidations::CardRules.rules.each do |name, rules|
   rules.each do |rule_value|
     CreditCardValidations::Detector.add_rule(name,
                                              rule_value[:length],
                                              rule_value[:prefixes],
                                              rule_value[:skip_validation])
  end

end

