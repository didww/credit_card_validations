# Switch cards were withdrawn from the market in 2002.
# Kept for legacy compatibility only — no new cards are issued.
CreditCardValidations.add_brand(
  :switch,
  [
    {:length=>[16, 18, 19], :prefixes=>["633110", "633312", "633304", "633303", "633301", "633300"]}
  ],
  code: {:name=>"CVV", :size=>3}
)
