module CocinaDisplay
  module Titles
    # A Title represented by one or more {TitleValue}s in various languages/scripts.
    class Title
      # The underlying Cocina hash.
      attr_reader :cocina

      # Status of the title, e.g. "primary".
      # @return [String, nil]
      attr_accessor :status

      # Common display methods reference the main title value. For parallel
      # values, see #translated_value and #transliterated_value.
      delegate :short_title, :full_title, :display_title, :sort_title, to: :main_value

      # Create a new Title object.
      # @param cocina [Hash]
      # @param part_label [String, nil] part label for digital serials
      # @param part_numbers [Array<String>] part numbers for related resources
      def initialize(cocina, part_label: nil, part_numbers: nil)
        @cocina = cocina
        @part_label = part_label
        @part_numbers = part_numbers
      end

      # Label used when displaying the title.
      # @return [String]
      def label
        cocina["displayLabel"].presence || type_label
      end

      # Type of the title, e.g. "uniform", "alternative", etc.
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#title-types
      # @return [String, nil]
      def type
        cocina["type"].presence || main_value.type
      end

      # Does this title have a type?
      # @return [Boolean]
      def type?
        type.present?
      end

      # Is this marked as a primary title?
      # @return [Boolean]
      def primary?
        status == "primary"
      end

      # The string representation of the title, for display.
      # @return [String, nil]
      def to_s
        display_title
      end

      # The main value of the title, ignoring parallel values if any.
      # If no value is marked as parallel, returns the first value.
      # @return [TitleValue]
      def main_value
        title_values.find(&:main_value?) || title_values.first
      end

      # All values except the main value.
      # @return [Array<TitleValue>]
      def parallel_values
        title_values.reject { |value| value.to_s == main_value.to_s }
      end

      # The translated version of the title, if any.
      # @return [TitleValue, nil]
      def translated_value
        title_values.find(&:translated?)
      end

      # Is there a translated version of the title?
      # @return [Boolean]
      def has_translation?
        translated_value.present?
      end

      # The transliterated version of the title, if any.
      # @return [TitleValue, nil]
      def transliterated_value
        title_values.find(&:transliterated?)
      end

      # Is there a transliterated version of the title?
      # @return [Boolean]
      def has_transliteration?
        transliterated_value.present?
      end

      # Individual values in different languages/scripts composing this title.
      # @return [Array<TitleValue>]
      def title_values
        @title_values ||= begin
          # Create TitleValue objects for all parallelValue nodes or just value if none
          values = (Array(cocina["parallelValue"]).presence || [cocina]).map do |node|
            TitleValue.new(node, part_label: @part_label, part_numbers: @part_numbers)
          end

          # If there's only one value, we're done
          return values if values.one?

          # Set the type of the parallel values to either their sibling main value's type
          # or the parent title's type.
          main_type = values.find(&:main_value?)&.type || cocina["type"].presence
          values.each { |value| value.type ||= main_type }
          values
        end
      end

      private

      # Type-specific label for the title, falling back to a generic "Title".
      # @return [String]
      def type_label
        I18n.t(type&.parameterize&.underscore, scope: "cocina_display.field_label.title", default: :title)
      end
    end
  end
end
