# 3.4.0
   * Elo support enhanced, PR #75
   
# 3.3.0
   * Added support for MIR card brand

# 3.2.2
   * Relaxing dependency requirements to support Rails 5

# 3.2.1
   * Improved support for new Mastercard range (222100 – 272099)

# 3.2.0
   * Added support for new Mastercard range (222100 – 272099)

# 3.1.0
   * Added support for ELO brand

# 3.0.0
   * Remove Laser brand because Laser cards were withdrawn from the market on February 28 2014
   * Remove Diners US brand for similar reason
   * Move Laser ranges to Maestro. Add 6390 range to Maestro
   * Add plugins for removed brands

# 2.0.2
   * fix using ActiveModel Validator's message option

# 2.0.1
   * fix typo dankrot -> dankort

# 2.0.0

  * added support for full brand names
  * added possibility to remove card brands globally
  * support for procs using :brand option for CreditCardNumberValidator
  * :only and :except options for CreditCardNumberValidator
  * credit card generator
  * test unit -> specs migration
  * card rules structure changed to allow custom options
  * yaml storage implemented
  * Maestro detection fix
  * JCB detection fix


# 1.5.1

  * Maestro detection fix

# 1.5.0

  * Rupay detection support
  * Hipercard detection support

# 1.4.7

  * Maestro and Switch detection fix

# 1.4.6

  * JCB detection fix

# 1.4.5

  * Diners detection fix

# 1.4.4

  * Visa detection fix

# 1.4.3

  * fix for Rails 4.+ dependency
  * Maestro detection fixes

# 1.4.2

  * fix for Rails 4.1 dependency
  * UnionPay and Discover detection fixes

# 1.4.1

  * fixed ActiveModel Validator syntax

# 1.4.0

  *  Dankort brand support

# 1.3.0

  * MMI detection support

# 1.2.0

  * Allow brand restriction when detecting brand
  * fix for Rails 4.0 dependency
  * Allow to skip Luhn validation for certain brands

# 1.1.2

  * Credit card number sanitizing fix
  * :any instead of brand name can be used with ActiveModel Validator

# 1.1.1

  * ActiveModel Validator was moved from root namespace

# 1.1.0

  * Added rules for Maestro brand
  * String extension added

# 1.0.1

  * Dependency fixes
  * Added usage instructions to README
