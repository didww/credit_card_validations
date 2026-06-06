CreditCardValidations.add_brand(
  :dankort,
  [
    {:length=>[16], :prefixes=>["5019"]}
  ],
  code: {:name=>"CVV", :size=>3}
)
