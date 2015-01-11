module CreditCardValidations
  class Detector

    include Mmi

    class_attribute :brands
    self.brands = {}

    attr_reader :number

    def initialize(number)
      @number = number.to_s.tr('- ', '')
    end

    # credit card number
    def valid?(*brands)
      !!valid_number?(*brands)
    end

    #brand name
    def brand(*keys)
      valid_number?(*keys)
    end


    def valid_number?(*keys)
      selected_brands = keys.blank? ? self.brands : self.brands.slice(*keys.map { |el| el.downcase })
      if selected_brands.any?
        selected_brands.each do |key, brand|
          return key if matches_brand?(brand)
        end
      end
      nil
    end

    #check if luhn valid
    def valid_luhn?
      @valid_luhn ||= Luhn.valid?(number)
    end

    protected
    def matches_brand?(brand)
      rules = brand.fetch(:rules)
      options = brand.fetch(:options, {})

      rules.each do |rule|
        if (options[:skip_luhn] || valid_luhn?) &&
            rule[:length].include?(number.length) &&
            number.match(rule[:regexp])
          return true
        end

      end
      false
    end

    class << self

      def add_brand(key, rules, options = {})

        brands[key] = {rules: [], options: options || {}}

        Array.wrap(rules).each do |rule|
          add_rule(key, rule[:length], rule[:prefixes])
        end

        add_brand_method(key)

      end

      #create rule for detecting brand
      def add_rule(key, length, prefixes)
        unless brands.has_key?(key)
          raise RuntimeError.new("brand #{key} is undefined, please use #add_brand method")
        end
        length, prefixes = Array(length), Array(prefixes)
        brands[key][:rules] << {length: length, regexp: compile_regexp(prefixes), prefixes: prefixes}
      end

      protected

      def add_brand_method(key)
        define_method "#{key}?".to_sym do
          valid?(key)
        end unless method_defined? "#{key}?".to_sym
      end

      #create regexp by array of prefixes
      def compile_regexp(prefixes)
        Regexp.new("^((#{prefixes.join(")|(")}))")
      end

    end

  end

end
