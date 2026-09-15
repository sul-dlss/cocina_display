module CocinaDisplay
  module Events
    # A location in a Cocina event in a single language/script.
    class LocationValue < Parallel::ParallelValue
      # The name of the location.
      # Decodes a MARC country code if present and no value was present.
      # @return [String, nil]
      def to_s
        cocina["value"] || country_name
      end

      # Is there an unencoded value (name) for this location?
      # @return [Boolean]
      def unencoded_value?
        cocina["value"].present?
      end

      # Decoded country name if the location is encoded with a MARC country code.
      # @return [String, nil]
      def country_name
        Location.marc_countries[code] if marc_country? && valid_country_code?
      end

      private

      # A code, like a MARC country code, representing the location.
      # @return [String, nil]
      def code
        cocina["code"]
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
