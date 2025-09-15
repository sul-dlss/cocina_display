# frozen_string_literal: true

module CocinaDisplay
  # A language associated with part or all of a Cocina object.
  class Language
    attr_reader :cocina

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

    # Decoded name of the language based on the code, if present.
    # @return [String, nil]
    def decoded_value
      Vocabularies::SEARCHWORKS_LANGUAGES[code] if searchworks_language?
    end

    # Display label for this field.
    # @return [String]
    def label
      cocina["displayLabel"].presence || I18n.t("cocina_display.field_label.language")
    end

    # True if the language is recognized by Searchworks.
    # @see CocinaDisplay::Vocabularies::SEARCHWORKS_LANGUAGES
    # @return [Boolean]
    def searchworks_language?
      Vocabularies::SEARCHWORKS_LANGUAGES.value?(cocina["value"]) || Vocabularies::SEARCHWORKS_LANGUAGES.key?(code)
    end
  end
end
