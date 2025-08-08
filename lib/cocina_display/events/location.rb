require_relative "../vocabularies/marc_country_codes"

module CocinaDisplay
  module Events
    # A single location represented in a Cocina event, like a publication place.
    class Location
      attr_reader :cocina

      # Initialize a Location object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the location.
      def initialize(cocina)
        @cocina = cocina
      end

      # The name of the location.
      # Decodes a MARC country code if present and no value was present.
      # @return [String, nil]
      def to_s
        cocina["value"] || decoded_country
      end

      # Is there an unencoded value (name) for this location?
      # @return [Boolean]
      def unencoded_value?
        cocina["value"].present?
      end

      private

      # A code, like a MARC country code, representing the location.
      # @return [String, nil]
      def code
        cocina["code"]
      end

      # Decoded country name if the location is encoded with a MARC country code.
      # @return [String, nil]
      def decoded_country
        Vocabularies::MARC_COUNTRY[code] if marc_country? && valid_country_code?
      end

      # Is this a decodable country code?
      # Excludes blank values and "xx" (unknown) and "vp" (various places).
      # @return [Boolean]
      def valid_country_code?
        code.present? && ["xx", "vp"].exclude?(code)
      end

      # Is this location encoded with a MARC country code?
      # @return [Boolean]
      def marc_country?
        cocina.dig("source", "code") == "marccountry"
      end
    end
  end
end
