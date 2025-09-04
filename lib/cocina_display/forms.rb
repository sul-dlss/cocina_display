# frozen_string_literal: true

module CocinaDisplay
  # Classes for extracting format/genre information from a Cocina object.
  module Forms
    # A form associated with part or all of a Cocina object.
    class Form
      attr_reader :cocina

      # Create a Form object from Cocina structured data.
      # @param cocina [Hash]
      def initialize(cocina)
        @cocina = cocina
      end

      # The value to use for display.
      # Genre values are capitalized; other form values are not.
      # @return [String]
      def to_s
        (type == "genre") ? value&.upcase_first : value
      end

      # The raw value from the Cocina data.
      # @return [String]
      def value
        cocina["value"]
      end

      # The label to use for display.
      # Uses a displayLabel if available, otherwise looks up via type.
      # @return [String]
      def label
        cocina["displayLabel"].presence || type_label
      end

      # The type of form, such as "genre", "extent", etc.
      # @return [String, nil]
      def type
        cocina["type"]
      end

      private

      # Type-specific label for this form value.
      # @return [String]
      def type_label
        I18n.t(type&.parameterize&.underscore, default: :form, scope: "cocina_display.field_label.form")
      end
    end
  end
end
