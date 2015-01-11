require 'coveralls'
Coveralls.wear!

require 'minitest/autorun'
require 'i18n'
require 'mocha/mini_test'

lib = File.expand_path("#{File.dirname(__FILE__)}/../lib")
specs = File.expand_path("#{File.dirname(__FILE__)}/../spec")
$:.unshift(lib)
$:.unshift(specs)

I18n.config.enforce_available_locales = true

require 'credit_card_validations'
require 'models/credit_card'
require 'models/any_credit_card'

class CreditCardValidations::Specs < Minitest::Spec
  let(:valid_numbers) {
    YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/valid_cards.yml')
  }

  let(:invalid_numbers) {
    YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/invalid_cards.yml')
  }

end
