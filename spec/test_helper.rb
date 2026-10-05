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
PLUGIN_BRANDS = Dir[File.expand_path('../lib/credit_card_validations/plugins/*.rb', __dir__)]
                  .map { |path| File.basename(path, '.rb').to_sym }.sort.freeze

# Registers a plugin brand unless it is already registered. add_brand refuses
# a brand that is, and `load` re-runs the file, so specs that share a brand
# would fail on whichever ran second. An application uses `require`, which is
# idempotent; this is the same guarantee. A key with no plugin file -- a
# default brand -- is a no-op, since callers pass whole fixture key lists.
def load_plugin(brand)
  brand = brand.to_sym
  return unless PLUGIN_BRANDS.include?(brand)
  return if CreditCardValidations::Detector.brands.key?(brand)
  load "credit_card_validations/plugins/#{brand}.rb"
end

require 'models/credit_card'

VALID_NUMBERS = YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/valid_cards.yml')
INVALID_NUMBERS = YAML.load_file File.join(File.dirname(__FILE__), 'fixtures/invalid_cards.yml')
OVERRIDED_BRANDS_FILE =  File.join(File.dirname(__FILE__), 'fixtures/overrided_brands.yml')

