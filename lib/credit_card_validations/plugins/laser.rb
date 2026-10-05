# 6771 is absent on purpose: :maestro declares it too, at a length both
# accept. Laser was a Maestro co-badge, so :maestro keeps the range.
CreditCardValidations.add_brand(
  :laser,
  length: [16, 17, 18, 19], prefixes: %w(6304 6706)
)
