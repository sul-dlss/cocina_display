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
      Vocabularies::SEARCHWORKS_LANGUAGES[code] || (Iso639[code] if iso_639?)
    end

    # True if the language is recognized by Searchworks.
    # @see CocinaDisplay::Vocabularies::SEARCHWORKS_LANGUAGES
    # @return [Boolean]
    def searchworks_language?
      Vocabularies::SEARCHWORKS_LANGUAGES.value?(to_s)
    end

    # True if the language has a code sourced from the ISO 639 vocabulary.
    # @see https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes
    # @return [Boolean]
    def iso_639?
      cocina.dig("source", "code")&.start_with? "iso639"
    end
  end
end
