# == CreditCardValidations Detector
#
# class provides credit card number validations
module CreditCardValidations
  class Detector

    include Mmi

    class_attribute :brands
    self.brands = {}

    attr_reader :number

    def initialize(number)
      @number = number.to_s.tr('- ', '')
    end

    # credit card number validation
    def valid?(*brands)
      !!valid_number?(*brands)
    end

    #brand name
    def brand(*keys)
      valid_number?(*keys)
    end

    def valid_number?(*keys)
      selected_brands = keys.blank? ? self.brands : resolve_keys(*keys)
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

    def brand_name
      self.class.brand_name(brand)
    end

    protected

    def resolve_keys(*keys)
      brand_keys = keys.map do |el|
        if el.is_a? String
          #try to find key by name
          el = (self.class.brand_key(el) || el).to_sym
        end
        el.downcase
      end
      self.brands.slice(*brand_keys)
    end

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

      def has_luhn_check_rule?(key)
        !brands[key].fetch(:options, {}).fetch(:skip_luhn, false)
      end

      #
      # add brand
      #
      #   CreditCardValidations.add_brand(:en_route, {length: 15, prefixes: ['2014', '2149']}, {skip_luhn: true}) #skip luhn
      #
      def add_brand(key, rules, options = {})

        brands[key] = {rules: [], options: options || {}}

        Array.wrap(rules).each do |rule|
          add_rule(key, rule[:length], rule[:prefixes])
        end

        define_brand_method(key)

      end

      def brand_name(brand_key)
        brand = brands[brand_key]
        if brand
          brand.fetch(:options, {})[:brand_name] || brand_key.to_s.titleize
        else
          nil
        end
      end

      def brand_key(brand_name)
        brands.detect do |_, brand|
          brand[:options][:brand_name] == brand_name
        end.try(:first)
      end

      # CreditCardValidations.delete_brand(:en_route)
      def delete_brand(key)
        key = key.to_sym
        undef_brand_method(key)
        brands.reject! { |k, _| k == key }
      end

      #create rule for detecting brand
      def add_rule(key, length, prefixes)
        unless brands.has_key?(key)
          raise Error.new("brand #{key} is undefined, please use #add_brand method")
        end
        length, prefixes = Array(length), Array(prefixes)
        brands[key][:rules] << {length: length, regexp: compile_regexp(prefixes), prefixes: prefixes}
      end

      protected

      # create methods like visa?,  maestro? etc
      def define_brand_method(key)
        define_method "#{key}?".to_sym do
          valid?(key)
        end unless method_defined? "#{key}?".to_sym
      end

      def undef_brand_method(key)
        undef_method "#{key}?".to_sym if method_defined? "#{key}?".to_sym
      end

      #create regexp by array of prefixes
      def compile_regexp(prefixes)
        Regexp.new("^((#{prefixes.join(")|(")}))")
      end

    end
  end
end
