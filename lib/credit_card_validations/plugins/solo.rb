# Solo cards were withdrawn from the market in 2011.
# Kept for legacy compatibility only — no new cards are issued.
CreditCardValidations.add_brand(
  :solo,
  [
    {:length=>[16, 18, 19], :prefixes=>["6334", "6767"]}
  ],
  code: {:name=>"CVV", :size=>3}
)
