module CreditCardValidations
  class Detector

    include Mmi

    class_attribute :rules
    self.rules = {}

    attr_reader :number

    def initialize(number)
      @number = number.to_s.tr('- ','')
    end

    # credit card number
    def valid?(*brands)
       !!valid_number?(*brands)
    end

    #brand name
    def brand(*brands)
       valid_number?(*brands)
    end

    def valid_number?(*brands)
      number_length = number.length
      brand_rules = brands.blank? ? self.rules : self.rules.slice(*brands.map{ |el| el.downcase })
      unless brand_rules.blank?
        brand_rules.each do |brand_name, rules|
          rules.each do |rule|
            return brand_name if ( (rule[:skip_validation] || valid_luhn?) and rule[:length].include?(number_length) and number.match(rule[:regexp]))
          end
        end
      end
      nil
    end

    #check if luhn valid
    def valid_luhn?
      @valid_luhn ||= Luhn.valid?(number)
    end

    class << self

      #create regexp by array of prefixes
      def compile_regexp(prefixes)
          Regexp.new("^((#{prefixes.join(")|(")}))")
      end

      #create rule for detecting brand
      def add_rule(brand, length, prefixes, skip_validation = false)
        prefixes = Array.wrap(prefixes)
        length = Array.wrap(length)
        rules[brand] = [] if rules[brand].blank?
        rules[brand] << {length: length,  regexp: compile_regexp(prefixes), prefixes: prefixes, skip_validation: skip_validation}
        #create methods like  visa? mastercard? etc
        class_eval <<-BOOLEAN_RULE, __FILE__, __LINE__
          def #{brand}?
             valid?(:#{brand})
          end
        BOOLEAN_RULE
      end
    end

    CardRules.constants.each do |const_name|
      CardRules.const_get(const_name).each do |const_value|
        self.add_rule(const_name.to_s.downcase.to_sym , const_value[:length], const_value[:prefixes], const_value[:skip_validation])
      end

    end
  end


end
