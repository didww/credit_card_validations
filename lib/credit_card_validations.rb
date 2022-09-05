require 'credit_card_validations/version'
require 'credit_card_validations/configuration'
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

  attr_accessor :configuration

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
    reload!
  end

  def self.add_brand(key, rules, options = {})
    Detector.add_brand(key, rules, options)
  end

  def self.source
    configuration.source || File.join(File.join(File.dirname(__FILE__)), 'data', 'brands.yaml')
  end

  def self.data
    YAML.load_file(source) || {}
  end

  def self.reload!
    Detector.brands = {}
    data.each do |key, data|
      add_brand(key, data.fetch(:rules), data.fetch(:options, {}))
    end
  end

end

CreditCardValidations.reload!



