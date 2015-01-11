# == CreditCardValidations Mmi
#
# Implements Major Industry Identifier (MII) detection
#
# The first digit of a credit card number is the Major Industry Identifier (MII), which represents the category of entity which issued the card. MII digits represent the following issuer categories:
# 0 – ISO/TC 68 and other future industry assignments
# 1 – Airlines
# 2 – Airlines and other future industry assignments
# 3 – Travel and entertainment and banking/financial
# 4 – Banking and financial
# 5 – Banking and financial
# 6 – Merchandising and banking/financial
# 7 – Petroleum and other future industry assignments
# 8 – Healthcare, telecommunications and other future industry assignments
# 9 – National assignment
# For example, American Express, Diner's Club, Carte Blanche,
# and JCB are in the travel and entertainment category;
# VISA, MasterCard, and Discover are in the banking and financial category (Discover being in the Merchandising and banking/financial category);
# and Sun Oil and Exxon are in the petroleum category.


module CreditCardValidations
  module Mmi

    ISSUER_CATEGORIES = {
        '0' => 'ISO/TC 68 nd other industry assignments',
        '1' => 'Airlines',
        '2' => 'Airlines and other industry assignments',
        '3' => 'Travel and entertainment and banking/financial',
        '4' => 'Banking and financial',
        '5' => 'Banking and financial',
        '6' => 'Merchandising and banking/financial',
        '7' => 'Petroleum and other industry assignments',
        '8' => 'Healthcare, telecommunications and other industry assignments',
        '9' => 'National assignment'

    }

    def issuer_category
      ISSUER_CATEGORIES[@number.to_s[0]]
    end
  end
end
