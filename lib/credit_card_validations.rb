require 'credit_card_validations/version'
require 'credit_card_validations/error'
require 'active_model'
require 'active_support/core_ext'
require 'active_model/validations'
require 'active_model/credit_card_number_validator'
require 'yaml'

module CreditCardValidations
  extend ActiveSupport::Autoload
  autoload :VERSION, 'credit_card_validations/version'
  autoload :Luhn, 'credit_card_validations/luhn'
  autoload :Detector, 'credit_card_validations/detector'
  autoload :Factory, 'credit_card_validations/factory'
  autoload :Mmi, 'credit_card_validations/mmi'


  def self.add_brand(key, rules, options = {})
    Detector.add_brand(key, rules, options)
  end

  DATA = YAML.load_file(File.join(File.dirname(__FILE__),  'data', 'brands.yaml')) || {}

  def self.reload!
    Detector.brands = {}
    DATA.each do |key, data|
      add_brand(key, data.fetch(:rules), data.fetch(:options, {}))
    end
  end

end

CreditCardValidations.reload!



