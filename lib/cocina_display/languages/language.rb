# frozen_string_literal: true

module CocinaDisplay
  module Languages
    # A language associated with part or all of a Cocina object.
    class Language
      SEARCHWORKS_LANGUAGES_FILE_PATH = CocinaDisplay.root / "config" / "searchworks_languages.yml"

      attr_reader :cocina

      # A hash of language codes to language names recognized by Searchworks.
      # @return [Hash{String => String}]
      def self.searchworks_languages
        @searchworks_languages ||= YAML.safe_load_file(SEARCHWORKS_LANGUAGES_FILE_PATH)
      end

      # Create a Language object from Cocina structured data.
      # @param cocina [Hash]
      def initialize(cocina)
        @cocina = cocina
      end

      # The language name for display.
      # @return [String, nil]
      def to_s
        cocina["value"] || decoded_value
      end

      # The language code, e.g. an ISO 639 code like "eng" or "spa".
      # @return [String, nil]
      def code
        cocina["code"]
      end

      # The IETF tag describing this language and script, if available.
      # @return [String, nil]
      # @example "ara-Latn" for Arabic written in Latin script
      # @see https://en.wikipedia.org/wiki/IETF_language_tag
      def ietf_tag
        return code unless transliterated?

        "#{code}-#{script.code}"
      end

      # True if the value is transliterated, i.e. non-English written in Latin script.
      # @return [Boolean]
      def transliterated?
        !english? && script&.latin?
      end

      # True if the language is English.
      # @return [Boolean]
      def english?
        to_s == "English"
      end

      # Decoded name of the language based on the code, if present.
      # @return [String, nil]
      def decoded_value
        Language.searchworks_languages[code] if searchworks_language?
      end

      # Display label for this field.
      # @return [String]
      def label
        cocina["displayLabel"].presence || I18n.t("cocina_display.field_label.language")
      end

      # True if the language is recognized by Searchworks.
      # @see CocinaDisplay::Language.searchworks_languages
      # @return [Boolean]
      def searchworks_language?
        Language.searchworks_languages.value?(cocina["value"]) || Language.searchworks_languages.key?(code)
      end

      # The script of the language, if specified.
      # @return [CocinaDisplay::Languages::Script, nil]
      def script
        CocinaDisplay::Languages::Script.new(script_cocina) if script_cocina.present?
      end

      private

      # The script might be in "script" (top-level) or "valueScript" (nested).
      # @return [Hash, nil]
      def script_cocina
        cocina["valueScript"] || cocina["script"]
      end
    end
  end
end
