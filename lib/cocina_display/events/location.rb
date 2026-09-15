module CocinaDisplay
  module Events
    # A location represented in a Cocina event, like a publication place.
    # Can be expressed as several {LocationValue}s in different languages/scripts.
    class Location < Parallel::Parallel
      MARC_COUNTRIES_FILE_PATH = CocinaDisplay.root / "config" / "marc_countries.yml"

      # Common display methods reference the main location value. For parallel
      # values, see #translated_value and #transliterated_value.
      delegate :to_s, :unencoded_value?, :country_name, to: :main_value

      # A hash mapping MARC country codes to their names.
      # @return [Hash{String => String}]
      def self.marc_countries
        @marc_countries ||= YAML.safe_load_file(MARC_COUNTRIES_FILE_PATH)
      end

      private

      # The class to use for parallel values.
      # @return [Class]
      def parallel_value_class
        LocationValue
      end
    end
  end
end
