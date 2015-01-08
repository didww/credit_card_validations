require 'coveralls'
Coveralls.wear!

require 'minitest/autorun'
require 'i18n'
require 'mocha/mini_test'

lib = File.expand_path("#{File.dirname(__FILE__)}/../lib")
unit_tests = File.expand_path("#{File.dirname(__FILE__)}/../test")
$:.unshift(lib)
$:.unshift(unit_tests)

I18n.config.enforce_available_locales = true

require 'credit_card_validations'
require 'models/credit_card'
require 'models/any_credit_card'



