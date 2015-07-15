CreditCardValidations.add_brand(
  :en_route,
  { length: 15, prefixes: %w(2014 2149) },
  skip_luhn: true
)
