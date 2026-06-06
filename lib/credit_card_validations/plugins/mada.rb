# Prefixes sourced from ActiveMerchant's MADA_RANGES. Open BIN datasets
# tend to label Mada cards under their underlying Mastercard/Visa rails;
# this plugin is the canonical way to detect Mada specifically.
CreditCardValidations.add_brand(
  :mada,
  {
    length: 16,
    prefixes: %w(
      504300 506968 508160 585265 588848 588850
      588982 588983 589005 589206 604906 605141 636120
      968201 968202 968203 968204 968205
      968206 968207 968208 968209 968211
    )
  },
  brand_name: 'Mada',
  code: { name: 'CVV', size: 3 }
)
