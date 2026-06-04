# PagoBancomat is the Italian national debit network. BINs are issued by
# many cooperating Italian banks; the prefixes below cover the most common
# institutions observed in the public BIN dataset.
CreditCardValidations.add_brand(
  :pagobancomat,
  {
    length: 16,
    prefixes: %w(
      02 03 05 06 080 084 085 089 095
    )
  },
  brand_name: 'PagoBancomat'
)
