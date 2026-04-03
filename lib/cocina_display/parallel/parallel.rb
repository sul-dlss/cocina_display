module CocinaDisplay
  module Parallel
    # A base class for objects that have ParallelValues as children
    class Parallel
      # The underlying Cocina hash.
      # @return [Hash]
      attr_reader :cocina

      # Initialize a Parallel object with Cocina data.
      # @param cocina [Hash]
      def initialize(cocina)
        @cocina = cocina
      end

      # The type, which can be inherited from the main parallel value if absent.
      # @return [String, nil]
      def type
        own_type || main_value.own_type
      end

      # Does this object have a type?
      # @return [Boolean]
      def typed?
        type.present?
      end

      # The type of this object in the Cocina.
      # @return [String, nil]
      def own_type
        cocina["type"].presence
      end

      # Does this object have a type defined in the Cocina?
      # @return [Boolean]
      def own_typed?
        own_type.present?
      end

      # Create ParallelValue objects for all parallelValue nodes, or just value if only one
      # @return [Array<CocinaDisplay::ParallelValue>]
      def parallel_values
        @parallel_values ||= (Array(cocina["parallelValue"]).presence || [cocina]).map do |node|
          parallel_value_class.new(node, parent: self)
        end
      end

      # The main value among the parallel values, according to these rules:
      # 1. If there's a parallelValue with type "display", use that.
      # 2. If there's a parallelValue marked as primary, use that.
      # 3. If there's a parallelValue in a vernacular (non-English) language, use that.
      # 4. If there's a parallelValue with a non-role type, like "alternative", use that.
      # 5. Otherwise, use the first parallelValue.
      # @return [CocinaDisplay::ParallelValue, nil]
      def main_value
        parallel_values.find(&:display?) ||
          parallel_values.find(&:primary?) ||
          parallel_values.find(&:vernacular?) ||
          parallel_values.find(&:own_typed?) ||
          parallel_values.first
      end

      # The translated value for this object, if any.
      # @return [CocinaDisplay::ParallelValue, nil]
      def translated_value
        parallel_values.find(&:translated?)
      end

      # Is there a translated version of the object?
      # @return [Boolean]
      def has_translation?
        translated_value.present?
      end

      # The transliterated version of the object, if any.
      # @return [CocinaDisplay::ParallelValue, nil]
      def transliterated_value
        parallel_values.find(&:transliterated?)
      end

      # Is there a transliterated version of the object?
      # @return [Boolean]
      def has_transliteration?
        transliterated_value.present?
      end

      # The vernacular (non-English) version of the object, if any.
      # @return [CocinaDisplay::ParallelValue, nil]
      def vernacular_value
        parallel_values.find(&:vernacular?)
      end

      # Is there a vernacular (non-English) version of the object?
      # @return [Boolean]
      def has_vernacular?
        vernacular_value.present?
      end

      # The status of the object relative to others, if any (e.g., "primary").
      # @return [String, nil]
      def status
        cocina["status"]
      end

      # Is this object marked as primary?
      # @return [Boolean]
      def primary?
        status == "primary"
      end

      private

      # The display label set in Cocina
      # @return [String, nil]
      def display_label
        cocina["displayLabel"].presence
      end

      # The class to use for parallel values. Override in including classes.
      # @return [Class]
      # :nocov: start
      def parallel_value_class
        ParallelValue
      end
      # :nocov: stop
    end
  end
end
