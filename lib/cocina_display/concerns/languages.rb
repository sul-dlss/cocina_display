require_relative "../language"

module CocinaDisplay
  module Concerns
    # Methods for extracting language information from a Cocina object.
    module Languages
      # Languages objects associated with the object.
      # @return [Array<CocinaDisplay::Language>]
      def languages
        @languages ||= path("$.description.language.*").map { |lang| CocinaDisplay::Language.new(lang) }
      end

      # Names of languages associated with the object, if recognized by Searchworks.
      # @return [Array<String>]
      def searchworks_language_names
        languages.filter_map { |lang| lang.display_str if lang.searchworks_language? }.compact_blank.uniq
      end
    end
  end
end
