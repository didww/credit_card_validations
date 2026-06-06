# == CreditCardValidations Detector
#
# class provides credit card number validations
module CreditCardValidations
  class Detector

    include Mmi

    class_attribute :brands
    self.brands = {}

    # Brands that were part of the default set up to v8.x and moved to
    # opt-in plugins in v9.0. The shim below auto-loads the plugin on first
    # reference and emits a one-time deprecation warning. To be removed in
    # v10.0 — users should add explicit `require` statements by then.
    LEGACY_PLUGIN_BRANDS = %i[mir rupay elo dankort hipercard solo switch].freeze
    @@legacy_autoloaded = {}

    attr_reader :number

    def initialize(number)
      @number = number.to_s.gsub(/[\s\-]/, '')
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
        matched_brands = []
        selected_brands.each do |key, brand|
          match_data = matches_brand?(brand)
          matched_brands << {brand: key, matched_prefix_length: match_data.to_s.length} if match_data
        end

        if matched_brands.present?
          return matched_brands.sort{|a, b| a[:matched_prefix_length] <=> b[:matched_prefix_length]}.last[:brand]
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

    # Last four digits of the PAN, or nil if the PAN has fewer than 4 digits.
    def last4
      number.length >= 4 ? number[-4, 4] : nil
    end

    # PAN with every digit but the last 4 replaced by mask_char.
    # Returns the original number when shorter than 4 digits — never raises.
    def masked(mask_char = '*')
      return number if number.length < 4
      mask_char.to_s[0] * (number.length - 4) + last4.to_s
    end

    # All brands whose prefixes can still match the (possibly partial) PAN.
    # Length and Luhn are not checked — useful for live UX before the user
    # finishes typing.
    def possible_brands
      return [] if number.empty?
      self.class.brands.each_with_object([]) do |(key, brand), acc|
        next unless brand.fetch(:rules).any? do |rule|
          rule[:prefixes].any? do |prefix|
            n = [number.length, prefix.length].min
            number[0, n] == prefix[0, n]
          end
        end
        acc << key
      end
    end

    # Human-readable PAN grouped per network convention. Falls back to the
    # first possible brand while the user is still typing.
    def formatted(separator = ' ')
      groups_for(brand || possible_brands.first).each_with_object([]) do |size, acc|
        slice = number[acc.join.length, size]
        acc << slice if slice && !slice.empty?
      end.join(separator)
    end

    # Validates the card verification value against the detected brand's
    # declared :code size. Returns false when the brand cannot be determined
    # from the PAN or the input has the wrong shape. Raises when a detected
    # brand is missing :code in the registry.
    def valid_cvv?(code)
      self.class.valid_cvv?(code, brand)
    end

    protected

    def groups_for(detected_brand)
      segments = self.class.brands.dig(detected_brand, :options, :segments)
      return segments if segments
      groups = Array.new(number.length / 4, 4)
      remainder = number.length % 4
      groups << remainder if remainder.positive?
      groups
    end

    def resolve_keys(*keys)
      brand_keys = keys.map do |el|
        if el.is_a? String
          #try to find key by name
          el = (self.class.brand_key(el) || el).to_sym
        end
        el.downcase
      end
      brand_keys.each { |k| autoload_legacy_plugin(k) }
      self.brands.slice(*brand_keys)
    end

    def autoload_legacy_plugin(key)
      return unless LEGACY_PLUGIN_BRANDS.include?(key)
      return if self.class.brands.key?(key)
      return if @@legacy_autoloaded[key]
      @@legacy_autoloaded[key] = true

      Warning.warn(
        "[credit_card_validations] :#{key} was moved to a plugin in v9.0. " \
        "Auto-loading 'credit_card_validations/plugins/#{key}' for backward " \
        "compatibility. Add `require 'credit_card_validations/plugins/#{key}'` " \
        "to your initializer to silence; auto-load is removed in v10.\n"
      )
      load "credit_card_validations/plugins/#{key}.rb"
    end

    def matches_brand?(brand)
      rules = brand.fetch(:rules)
      options = brand.fetch(:options, {})

      rules.each do |rule|
        if (options[:skip_luhn] || valid_luhn?) &&
            rule[:length].include?(number.length) &&
            match_data = number.match(rule[:regexp])
          return match_data
        end
      end
      false
    end

    class << self

      def has_luhn_check_rule?(key)
        !brands[key].fetch(:options, {}).fetch(:skip_luhn, false)
      end

      # Class-level CVV check: validates a code against an explicit brand,
      # without needing a Detector instance. Useful when only the brand is
      # known (form input bound to a brand select, separate CVV field, etc.).
      def valid_cvv?(code, brand)
        return false if code.nil? || brand.nil? || !code.to_s.match?(/\A\d+\z/)
        spec = brands.dig(brand, :options, :code)
        raise Error, "brand #{brand.inspect} has no :code option" if spec.nil?
        code.to_s.length == spec[:size]
      end

      #
      # add brand
      #
      #   CreditCardValidations.add_brand(:en_route, {length: 15, prefixes: ['2014', '2149']}, {skip_luhn: true}) #skip luhn
      #
      def add_brand(key, rules, options = {})
        # Mark legacy plugin brands as handled so the v9 auto-require shim
        # never re-loads them after the user takes any explicit action
        # (require, add_brand, or a later delete_brand).
        @@legacy_autoloaded[key] = true if LEGACY_PLUGIN_BRANDS.include?(key)

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
