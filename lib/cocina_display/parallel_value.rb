module CocinaDisplay
  # A base class for values representing one of several siblings describing
  # the same thing in different languages or scripts.
  class ParallelValue
    # Value types (in Cocina) that indicate the value is not the main value.
    PARALLEL_TYPES = ["parallel", "translated", "transliterated"]

    # The underlying Cocina hash.
    # @return [Hash]
    attr_reader :cocina

    # What relationship does this value have to its siblings?
    # @return [String, nil]
    attr_reader :role

    # The type, which can be inherited from the parent object. Note that
    # PARALLEL_TYPES are considered types in the Cocina, but we treat those
    # separately as "roles" instead of a type.
    # @return [String, nil]
    attr_accessor :type

    # Create a new ParallelValue object and set the appropriate role and type.
    # @param cocina [Hash]
    def initialize(cocina)
      @cocina = cocina
      @role = PARALLEL_TYPES.find { |role| cocina["type"] == role } || "main"
      @type = cocina["type"] if main_value?
    end

    # Is this value the main value?
    # @return [Boolean]
    def main_value?
      role == "main"
    end

    # Is this value translated?
    # @return [Boolean]
    def translated?
      role == "translated"
    end

    # Is this value transliterated?
    # @return [Boolean]
    def transliterated?
      role == "transliterated" || language&.transliterated?
    end

    # Does this value have a type (that isn't one of PARALLEL_TYPES)?
    # @return [Boolean]
    def type?
      type.present?
    end

    # The language of the value, if specified.
    # @return [CocinaDisplay::Languages::Language, nil]
    def language
      @language ||= CocinaDisplay::Languages::Language.new(cocina["valueLanguage"]) if cocina["valueLanguage"].present?
    end
  end
end
