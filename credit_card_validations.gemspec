# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'credit_card_validations/version'

Gem::Specification.new do |gem|
  gem.name          = 'credit_card_validations'
  gem.version       = CreditCardValidations::VERSION
  gem.authors       = ['Igor']
  gem.email         = ['fedoronchuk@gmail.com']
  gem.description   = %q{A ruby gem for validating credit card numbers}
  gem.summary       = 'gem should be used for credit card numbers validation, card brands detections, luhn checks'
  gem.homepage      = 'https://github.com/didww/credit_card_validations'
  gem.license       = 'MIT'
  gem.required_ruby_version = '>= 3.3'

  gem.metadata    = {
    'bug_tracker_uri'   => 'https://github.com/didww/credit_card_validations/issues',
    'changelog_uri'     => 'https://github.com/didww/credit_card_validations/releases',
    'source_code_uri'   => 'https://github.com/didww/credit_card_validations'
  }

  # Tracked files only. A glob would ship whatever happens to sit in lib/ at
  # build time, and the release is built by hand from a working tree.
  gem.files = `git ls-files -z lib`.split("\x0") + [
    'LICENSE.txt',
    'README.md'
  ]

  gem.require_paths = ['lib']


  # Rails 7.1 reached end of life in October 2025 and 7.2 in August 2026; CI
  # has not tested either since. 8.0 is the oldest version actually covered.
  gem.add_dependency 'activemodel', '>= 8.0'
  gem.add_dependency 'activesupport', '>= 8.0'


  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'byebug'
end
