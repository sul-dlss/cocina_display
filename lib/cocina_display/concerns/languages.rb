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
        languages.filter_map { |lang| lang.to_s if lang.searchworks_language? }.compact_blank.uniq
      end

      # Language information for display.
      # @return [Array<CocinaDisplay::DisplayData>]
      def language_display_data
        languages.group_by(&:label).map do |label, langs|
          CocinaDisplay::DisplayData.new(label: label, values: langs.map(&:to_s).compact_blank.uniq)
        end.reject { |data| data.values.empty? }
      end
    end
  end
end
