# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'credit_card_validations/version'

Gem::Specification.new do |gem|
  gem.name          = "credit_card_validations"
  gem.version       = CreditCardValidations::VERSION
  gem.authors       = ["Igor"]
  gem.email         = ["fedoronchuk@gmail.com"]
  gem.description   = %q{A ruby gem for validating credit card numbers (a port of ZF2 Zend\Validator\CreditCard)}
  gem.summary       = "gem for credit card numbers validation, card brands detections"
  gem.homepage      = "https://github.com/Fivell/credit_card_validations"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]


  gem.add_dependency "activemodel", ">= 3.0", "<= 4.2"
  gem.add_dependency "activesupport", ">= 3.0", "<= 4.2"

  gem.add_development_dependency "test-unit",'~> 2.5'
  gem.add_development_dependency "mocha", '~> 0.12'
  gem.add_development_dependency 'rake', '~> 10'

end
