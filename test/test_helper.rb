require 'minitest/autorun'
require 'coveralls'
require 'i18n'
require 'mocha/mini_test'

lib = File.expand_path("#{File.dirname(__FILE__)}/../lib")
unit_tests = File.expand_path("#{File.dirname(__FILE__)}/../test")
$:.unshift(lib)
$:.unshift(unit_tests)

I18n.config.enforce_available_locales = true
Coveralls.wear!