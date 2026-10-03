require 'credit_card_validations/version'
require 'credit_card_validations/configuration'
require 'credit_card_validations/error'
require 'active_model'
require 'active_support/core_ext'
require 'active_model/validations'
require 'active_model/credit_card_number_validator'
require 'active_model/credit_card_cvv_validator'
require 'active_model/credit_card_expiration_validator'
require 'yaml'

module CreditCardValidations
  extend ActiveSupport::Autoload
  autoload :VERSION, 'credit_card_validations/version'
  autoload :Luhn, 'credit_card_validations/luhn'
  autoload :Detector, 'credit_card_validations/detector'
  autoload :Factory, 'credit_card_validations/factory'
  autoload :Mmi, 'credit_card_validations/mmi'
  autoload :Expiration, 'credit_card_validations/expiration'
  autoload :Card, 'credit_card_validations/card'
  autoload :BrandSet, 'credit_card_validations/brand_set'

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

  # Build an isolated brand set — detection scoped to a deep copy of the given
  # brands, taken out of the global registry now and unaffected by later
  # changes to it. Keys may be brand keys or brand names.
  #
  #   set = CreditCardValidations.with_brands(:visa, :mastercard)
  #   set.detect('4111 1111 1111 1111').brand #=> :visa
  #
  # Raises Error for a key that is not registered: a typo, or a plugin brand
  # whose plugin was never required. Also raises when given no keys at all.
  # Dropping either silently would reject a perfectly valid card in
  # production.
  def self.with_brands(*keys)
    BrandSet.new(keys.flatten)
  end

  def self.source
    configuration.source || File.join(File.join(File.dirname(__FILE__)), 'data', 'brands.yaml')
  end

  def self.data
    YAML.safe_load_file(source, permitted_classes: [Symbol]) || {}
  end

  def self.reload!
    Detector.brands = {}
    data.each do |key, data|
      add_brand(key, data.fetch(:rules), data.fetch(:options, {}))
    end
  end

end

CreditCardValidations.reload!



