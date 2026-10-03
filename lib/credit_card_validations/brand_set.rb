module CreditCardValidations
  # An isolated subset of the brand registry. The constructor takes a deep
  # copy of the requested brands out of the process-global Detector.brands;
  # from then on the set is a snapshot — later writes to the global registry
  # do not reach it, and nothing reached through it can write back.
  # Build one with CreditCardValidations.with_brands.
  class BrandSet

    def initialize(keys)
      keys = keys.map { |key| normalize(key) }
      @registry = Detector.brands.slice(*keys).deep_dup
      missing = keys - @registry.keys
      return if missing.empty?

      raise Error, "unknown brand(s) #{missing.map(&:inspect).join(', ')}; " \
                   "registered: #{Detector.brands.keys.map(&:inspect).join(', ')}" \
                   ' (a plugin brand needs its plugin required first)'
    end

    # Keys of the brands in this set, in the order they were requested.
    def brands
      registry.keys
    end

    def detect(number)
      Detector.new(number, brands: registry)
    end

    private

    # Live brand definitions of this set. Deliberately not public: handing
    # them out would let a caller edit the set from the outside.
    attr_reader :registry

    def normalize(key)
      key = Detector.brand_key(key) || key if key.is_a?(String)
      key.to_s.downcase.to_sym
    end

  end
end
