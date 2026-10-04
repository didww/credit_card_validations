module CreditCardValidations
  # A fixed list of brands to detect against, so the list is named once
  # instead of being repeated at every call site.
  #
  #   set = CreditCardValidations.with_brands(:visa, :mastercard)
  #   set.detect(pan).brand          # same as Detector.new(pan).brand(:visa, :mastercard)
  #   set.detect(pan).possible_brands # ...but this one has no per-call form
  #
  # Build one with CreditCardValidations.with_brands.
  #
  # A set narrows *which* brands are considered. It does not copy *what* they
  # are: the definitions are read from Detector.brands on every lookup, so a
  # set never disagrees with the rest of the process about what a Visa number
  # looks like. Two objects giving different answers for one card would be a
  # worse failure than the stale global registry a snapshot would protect
  # against.
  class BrandSet

    def initialize(keys)
      raise Error, 'with_brands needs at least one brand' if keys.empty?

      # Brand keys only, in any case: a list of brands usually arrives as
      # strings from a config file or an environment variable.
      @brands = keys.map { |key| key.to_s.downcase.to_sym }.freeze
      missing = @brands - Detector.brands.keys
      unless missing.empty?
        raise Error, "unknown brand(s) #{missing.map(&:inspect).join(', ')}; " \
                     "registered: #{Detector.brands.keys.map(&:inspect).join(', ')}" \
                     ' (a plugin brand needs its plugin required first)'
      end

      # A Detector subclass whose registry is the global one, narrowed to this
      # set. class_attribute gives every subclass its own `brands`, and every
      # lookup in Detector -- the class methods and the instance ones alike --
      # goes through it, so the whole API scopes with nothing added to
      # Detector itself. The reader is a method rather than a stored hash so
      # that it stays live.
      scoped_keys = @brands
      @detector_class = Class.new(Detector)
      @detector_class.define_singleton_method(:brands) do
        Detector.brands.slice(*scoped_keys)
      end
    end

    # Keys of the brands in this set, in the order they were requested.
    # Frozen: this is the set's own list, not a copy to edit.
    attr_reader :brands

    # A Detector that sees only this set's brands. It is a Detector, so the
    # whole instance API works on it.
    def detect(number)
      detector_class.new(number)
    end

    private

    attr_reader :detector_class

  end
end
