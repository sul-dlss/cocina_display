module CocinaDisplay
  module Events
    # A single location represented in a Cocina event, like a publication place.
    class Location
      MARC_COUNTRIES_FILE_PATH = CocinaDisplay.root / "config" / "marc_countries.yml"

      attr_reader :cocina

      # A hash mapping MARC country codes to their names.
      # @return [Hash{String => String}]
      def self.marc_countries
        @marc_countries ||= YAML.safe_load_file(MARC_COUNTRIES_FILE_PATH)
      end

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
        Location.marc_countries[code] if marc_country? && valid_country_code?
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
