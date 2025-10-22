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
  gem.homepage      = 'http://didww.github.io/credit_card_validations/'
  gem.license       = 'MIT'

  gem.metadata    = {
    'bug_tracker_uri'   => 'https://github.com/didww/credit_card_validations/issues',
    'changelog_uri'     => 'https://github.com/didww/credit_card_validations/blob/master/Changelog.md',
    'source_code_uri'   => 'https://github.com/didww/credit_card_validations'
  }

  gem.files = Dir.glob('lib/**/*') + [
    'Changelog.md',
    'Gemfile',
    'LICENSE.txt',
    'Rakefile',
    'README.md',
    'credit_card_validations.gemspec',
  ]

  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']


  gem.add_dependency 'activemodel', '>= 5.2', '< 8.2'
  gem.add_dependency 'activesupport', '>= 5.2', '< 8.2'


  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'byebug'
end
