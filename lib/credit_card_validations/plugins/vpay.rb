# V PAY is a Visa-issued European debit network. The BIN footprint is
# scattered (single-issuer prefixes); the list below covers the prefixes
# observed in the public BIN dataset.
CreditCardValidations.add_brand(
  :vpay,
  {
    length: 16,
    prefixes: %w(6310 6382 7389 7582 7628 7748 8820 8987 9451 9820 9887)
  },
  brand_name: 'V Pay'
)
