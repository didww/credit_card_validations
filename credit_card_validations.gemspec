# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'credit_card_validations/version'

Gem::Specification.new do |gem|
  gem.name          = "credit_card_validations"
  gem.version       = CreditCardValidations::VERSION
  gem.authors       = ["Igor"]
  gem.email         = ["fedoronchuk@gmail.com"]
  gem.description   = %q{A ruby gem for validating credit card numbers}
  gem.summary       = "gem should be used for credit card numbers validation, card brands detections, luhn checks"
  gem.homepage      = "http://didww.github.io/credit_card_validations/"
  gem.license       = "MIT"

  gem.metadata    = {
    'bug_tracker_uri'   => 'https://github.com/didww/credit_card_validations/issues',
    'changelog_uri'     => 'https://github.com/didww/credit_card_validations/blob/master/Changelog.md',
    'source_code_uri'   => 'https://github.com/didww/credit_card_validations'
  }

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]


  gem.add_dependency "activemodel", ">= 5.2", "< 8.1"
  gem.add_dependency "activesupport", ">= 5.2", "< 8.1"


  gem.add_development_dependency "minitest", '~> 5.14.3'
  gem.add_development_dependency "mocha", '1.1.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'byebug'
end
