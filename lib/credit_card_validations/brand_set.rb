module CreditCardValidations
  # An isolated subset of the brand registry. The constructor takes a deep
  # copy of the requested brands out of the process-global Detector.brands;
  # from then on the set is a snapshot — later writes to the global registry
  # do not reach it, and it is frozen, so nothing reached through it can be
  # edited in place either.
  # Build one with CreditCardValidations.with_brands.
  class BrandSet

    def initialize(keys)
      raise Error, 'with_brands needs at least one brand' if keys.empty?

      keys = keys.map { |key| normalize(key) }
      @registry = deep_freeze(Detector.brands.slice(*keys).deep_dup)
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

    # Frozen so the snapshot cannot be edited in place by anything that gets
    # hold of it -- including through the Detector that #detect builds, which
    # receives this very hash. Freezing beats copying per #detect: it costs
    # nothing per call and turns a silent corruption into a FrozenError.
    def deep_freeze(obj)
      case obj
      when Hash  then obj.each_value { |value| deep_freeze(value) }
      when Array then obj.each { |value| deep_freeze(value) }
      end
      obj.freeze
    end

    def normalize(key)
      key = Detector.brand_key(key) || key if key.is_a?(String)
      key.to_s.downcase.to_sym
    end

  end
end
