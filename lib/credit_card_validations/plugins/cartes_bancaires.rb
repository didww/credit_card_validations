# Prefixes sourced from ActiveMerchant's CARTES_BANCAIRES_RANGES. Open BIN
# datasets typically label CB cards under their co-branded Visa/Mastercard
# rails; this plugin is the canonical way to detect CB specifically.
CreditCardValidations.add_brand(
  :cartes_bancaires,
  {
    length: 16,
    prefixes: %w(
      507589 507590
      507593 507594 507595
      507597
      560408
      581752
      585402 585403 585404 585405
      585501 585502 585503 585504 585505
      585577 585578 585579 585580 585581 585582
    )
  },
  brand_name: 'Cartes Bancaires',
  code: { name: 'CVV', size: 3 }
)
