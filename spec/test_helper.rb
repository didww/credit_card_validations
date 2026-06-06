require 'minitest/autorun'
require 'i18n'
require 'mocha/minitest'
require 'byebug'

lib = File.expand_path("#{File.dirname(__FILE__)}/../lib")
specs = File.expand_path("#{File.dirname(__FILE__)}/../spec")
$:.unshift(lib)
$:.unshift(specs)

I18n.config.enforce_available_locales = true

require 'credit_card_validations'

# v9: brands that moved from core to plugins. Test fixtures still cover them,
# so specs that exercise legacy-brand fixtures call `load_legacy_plugin` on
# demand. We intentionally do NOT pre-load them here so the test environment
# mirrors the gem's default behavior (core brands only).
def load_legacy_plugin(brand)
  return unless CreditCardValidations::Detector::LEGACY_PLUGIN_BRANDS.include?(brand)
  load "credit_card_validations/plugins/#{brand}.rb"
end

require 'models/credit_card'

VALID_NUMBERS = YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/valid_cards.yml')
INVALID_NUMBERS = YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/invalid_cards.yml')
OVERRIDED_BRANDS_FILE =  File.join(File.dirname(__FILE__), 'fixtures/overrided_brands.yml')

