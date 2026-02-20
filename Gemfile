source 'https://rubygems.org'
group :test do
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'activemodel', github: 'rails/rails', branch: 'main', require: false
    gem 'activesupport', github: 'rails/rails', branch: 'main', require: false
  else
    gem 'activemodel', ENV['RAILS_VERSION'], require: false
    gem 'activesupport', ENV['RAILS_VERSION'], require: false
  end
end
# Specify your gem's dependencies in credit_card_validations.gemspec
gemspec
