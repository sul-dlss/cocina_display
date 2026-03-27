module CocinaDisplay
  module Parallel
    # A base class for values representing one of several siblings describing
    # the same thing in different languages or scripts.
    class ParallelValue
      # Value types (in Cocina) that are used to indicate sibling relationships.
      PARALLEL_TYPES = ["parallel", "translated", "transliterated", "display"].freeze

      # The underlying Cocina hash.
      # @return [Hash]
      attr_reader :cocina

      # The parent object that contains this value and its potential siblings.
      # @return [Object]
      attr_reader :parent

      # What relationship does this value have to its siblings?
      # @return [String, nil]
      attr_reader :role

      # The main value among the siblings, which could be this value.
      # @return [CocinaDisplay::ParallelValue]
      delegate :main_value, to: :parent

      # Create a new ParallelValue object and set the appropriate role and type.
      # @param cocina [Hash]
      # @param parent [Object] the parent object, used for inheritance
      def initialize(cocina, parent:)
        @cocina = cocina
        @parent = parent
        @role = PARALLEL_TYPES.find { |role| cocina["type"] == role }
      end

      # Sibling values with the same parent.
      # @return [Array<CocinaDisplay::ParallelValue>]
      def siblings
        parent.parallel_values.reject { |value| value == self }
      end

      # Is this value explicitly intended for display?
      # @return [Boolean]
      def display?
        role == "display"
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

      # The type, which can be inherited from the main sibling or parent object.
      # @return [String, nil]
      def type
        own_type || main_value.own_type || parent.own_type
      end

      # The type of this object in the Cocina, unless it's one of {PARALLEL_TYPES}.
      # @note {PARALLEL_TYPES} are types in Cocina, but we treat them as "roles".
      # @return [String, nil]
      def own_type
        cocina["type"] unless PARALLEL_TYPES.include?(cocina["type"])
      end

      # Does this value have a type?
      # @return [Boolean]
      def typed?
        type.present?
      end

      # Does this value have a type in the Cocina?
      # @note {PARALLEL_TYPES} are ignored since they indicate role, not type.
      # @return [Boolean]
      def own_typed?
        own_type.present?
      end

      # The language of the value, if specified.
      # @return [CocinaDisplay::Languages::Language, nil]
      def language
        @language ||= CocinaDisplay::Languages::Language.new(cocina["valueLanguage"]) if cocina["valueLanguage"].present?
      end

      private

      # The display label set in Cocina
      # @return [String, nil]
      def display_label
        cocina["displayLabel"].presence
      end
    end
  end
end
