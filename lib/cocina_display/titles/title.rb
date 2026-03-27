module CocinaDisplay
  module Titles
    # A Title represented by one or more {TitleValue}s in various languages/scripts.
    class Title < Parallel::Parallel
      # Part data for digital serials, coming from elsewhere in the Cocina.
      attr_reader :part_label, :part_numbers

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
        super(cocina)
        @part_label = part_label
        @part_numbers = part_numbers
      end

      # Label used when displaying the title.
      # @return [String]
      def label
        display_label || type_label
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

      private

      # Type-specific label for the title, falling back to a generic "Title".
      # @return [String]
      def type_label
        I18n.t(type&.parameterize&.underscore, scope: "cocina_display.field_label.title", default: :title)
      end

      # The class to use for parallel values.
      # @return [Class]
      def parallel_value_class
        TitleValue
      end
    end
  end
end
