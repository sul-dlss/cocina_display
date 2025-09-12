module CocinaDisplay
  module Events
    # A single note represented in a Cocina event, like an issuance or edition note.
    class Note
      attr_reader :cocina

      # Initialize a Note object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the note.
      def initialize(cocina)
        @cocina = cocina
      end

      # The value of the note.
      # @return [String, nil]
      def to_s
        cocina["value"].presence
      end

      # The type of the note, like "issuance" or "edition".
      # @return [String, nil]
      def type
        cocina["type"].presence
      end

      # The display label for the note.
      # @return [String]
      def label
        cocina["displayLabel"].presence ||
          I18n.t(type&.parameterize&.underscore, default: :default, scope: "cocina_display.field_label.event.note")
      end
    end
  end
end
