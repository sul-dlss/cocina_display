module CocinaDisplay
  module Concerns
    # Methods for extracting note information from Cocina.
    module Notes
      # Note objects associated with the cocina record.
      # @return [Array<CocinaDisplay::Note>]
      def notes
        @notes ||= path("$.description.note.*").map { |note| CocinaDisplay::Note.new(note) }
      end

      # Abstract metadata for display.
      # @return [Array<CocinaDisplay::DisplayData>]
      def abstract_display_data
        Utils.display_data_from_objects(notes.select(&:abstract?))
      end

      # General note metadata for display.
      # @return [Array<CocinaDisplay::DisplayData>]
      def general_note_display_data
        Utils.display_data_from_objects(notes.select(&:general_note?))
      end

      # Preferred citation metadata for display.
      # @return [Array<CocinaDisplay::DisplayData>]
      def preferred_citation_display_data
        Utils.display_data_from_objects(notes.select(&:preferred_citation?))
      end

      # Table of contents metadata for display.
      # @return [Array<CocinaDisplay::DisplayData>]
      def table_of_contents_display_data
        Utils.display_data_from_objects(notes.select(&:table_of_contents?))
      end
    end
  end
end
