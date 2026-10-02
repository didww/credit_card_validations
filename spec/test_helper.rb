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

# Brands that ship as opt-in plugins rather than in the default set. Fixtures
# still cover them, so specs load the plugin on demand. They are deliberately
# NOT pre-loaded here, so the test environment mirrors what an application gets
# out of the box: core brands only.
PLUGIN_BRANDS = %i[
  cabal carnet cartes_bancaires dankort dinacard diners_us elo en_route
  girocard hiper hipercard humocard laser mada mir naranja rupay solo switch
  troy uatp uzcard verve voyager vpay
].freeze

def load_legacy_plugin(brand)
  return unless PLUGIN_BRANDS.include?(brand)
  load "credit_card_validations/plugins/#{brand}.rb"
end

require 'models/credit_card'

VALID_NUMBERS = YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/valid_cards.yml')
INVALID_NUMBERS = YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/invalid_cards.yml')
OVERRIDED_BRANDS_FILE =  File.join(File.dirname(__FILE__), 'fixtures/overrided_brands.yml')

