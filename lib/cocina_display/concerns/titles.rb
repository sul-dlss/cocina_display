module CocinaDisplay
  module Concerns
    # Methods for finding and formatting titles.
    module Titles
      # The main title for the object, without subtitle, part name, etc.
      # If there are multiple primary titles, uses the first.
      # @see CocinaDisplay::Title#main_title
      # @return [String, nil]
      def main_title
        primary_title&.short_title
      end

      # The full title for the object, including subtitle, part name, etc.
      # If there are multiple primary titles, uses the first.
      # @see CocinaDisplay::Title#full_title
      # @return [String, nil]
      def full_title
        primary_title&.full_title
      end

      # The full title, joined together with additional punctuation.
      # If there are multiple primary titles, uses the first.
      # @see CocinaDisplay::Title#display_title
      # @return [String, nil]
      def display_title
        primary_title&.display_title
      end

      # A string value for sorting by title that sorts missing values last.
      # If there are multiple primary titles, uses the first.
      # @see CocinaDisplay::Title#sort_title
      # @return [String]
      def sort_title
        primary_title&.sort_title || "\u{10FFFF}"
      end

      # Any additional titles for the object excluding the primary title.
      # @return [Array<String>]
      # @see CocinaDisplay::Title#display_title
      def additional_titles
        secondary_titles.map(&:display_title).compact_blank
      end

      # All {Title} objects, grouped by their label for display.
      # @note All primary titles are included under "Title", not just the first.
      # @return [Array<DisplayData>]
      def title_display_data
        DisplayData.from_objects(all_titles)
      end

      # The first title marked primary, or the first without a type.
      # @return [Array<Title>]
      def primary_title
        all_titles.find { |title| title.primary? }.presence || all_titles.find { |title| !title.type? }
      end

      # All titles except the primary title.
      # @return [Array<Title>]
      def secondary_titles
        all_titles - [primary_title]
      end

      # All {Title} objects built from the Cocina titles.
      # Flattens parallel values into separate titles.
      # @return [Array<Title>]
      def all_titles
        @all_titles ||= cocina_titles.flat_map do |cocina_title|
          (Array(cocina_title["parallelValue"]).presence || [cocina_title]).map do |value|
            Title.new(value, part_label: part_label).tap do |title|
              title.type ||= cocina_title["type"]
              title.status ||= cocina_title["status"]
            end
          end
        end
      end

      private

      # The titles from the Cocina document, as an array of hashes.
      # @return [Array<Hash>]
      def cocina_titles
        @cocina_titles ||= Array(cocina_doc.dig("description", "title"))
      end

      # The catalog links from the Cocina document, as an array of hashes.
      # These link to FOLIO and can include part labels used to construct titles.
      # @return [Array<Hash>]
      def catalog_links
        @catalog_links ||= Array(cocina_doc.dig("identification", "catalogLinks"))
      end

      # Part label for digital serials display from FOLIO, if any.
      # @return [String, nil]
      def part_label
        catalog_links.find { |link| link["catalog"] == "folio" }&.fetch("partLabel", nil)
      end
    end
  end
end
