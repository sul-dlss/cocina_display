module CocinaDisplay
  module Description
    # Access information for a Cocina object.
    class Access
      attr_reader :cocina

      # Create an Access object from Cocina structured data.
      # @param cocina [Hash]
      def initialize(cocina)
        @cocina = cocina
      end

      # String representation of the access metadata.
      # @return [String, nil]
      def to_s
        cocina["value"].presence
      end

      # The type of the access metadata, e.g. "repository".
      # @return [String, nil]
      def type
        cocina["type"].presence
      end

      # The display label for the access metadata.
      # @return [String]
      def label
        cocina["displayLabel"].presence ||
          I18n.t(type&.parameterize&.underscore, default: :access, scope: "cocina_display.field_label.access")
      end

      # Whether the access info is a contact email.
      # Always false, see CocinaDisplay::Description::AccessContact
      # for cases when this is true
      # @return [Boolean]
      def contact_email?
        false
      end
    end
  end
end
