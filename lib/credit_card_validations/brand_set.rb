module CreditCardValidations
  # An isolated subset of the brand registry. Detection runs against these
  # brands only; the process-global Detector.brands is never read or written.
  # Build one with CreditCardValidations.with_brands.
  class BrandSet

    # Brand definitions of this set, keyed like Detector.brands.
    attr_reader :registry

    def initialize(keys)
      keys = keys.map { |key| normalize(key) }
      @registry = Detector.brands.slice(*keys)
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

    def normalize(key)
      key = Detector.brand_key(key) || key if key.is_a?(String)
      key.to_s.downcase.to_sym
    end

  end
end
