module CocinaDisplay
  module Concerns
    # Methods for finding and formatting titles.
    module Titles
      # The main title for the object, without subtitle, part name, etc.
      # If there are multiple titles, uses the first.
      # @see CocinaDisplay::TitleBuilder#main_title
      # @note This corresponds to the "short title" in MODS XML, or MARC 245$a only.
      # @return [String]
      def main_title
        CocinaDisplay::TitleBuilder.main_title(cocina_titles).first
      end

      # The full title for the object, including subtitle, part name, etc.
      # If there are multiple titles, uses the first.
      # @see CocinaDisplay::TitleBuilder#full_title
      # @note This corresponds to the entire MARC 245 field.
      # @return [String]
      def full_title
        CocinaDisplay::TitleBuilder.full_title(cocina_titles, catalog_links: catalog_links).first
      end

      # The full title, joined together with additional punctuation.
      # If there are multiple titles, uses the first.
      # @see CocinaDisplay::TitleBuilder#build
      # @return [String]
      def display_title
        CocinaDisplay::TitleBuilder.build(cocina_titles, catalog_links: catalog_links)
      end

      # Any additional titles for the object excluding the main title.
      # @return [Array<String>]
      # @see CocinaDisplay::TitleBuilder#additional_titles
      def additional_titles
        CocinaDisplay::TitleBuilder.additional_titles(cocina_titles)
      end

      # A string value for sorting by title that sorts missing values last.
      # Ignores punctuation, leading/trailing spaces, and non-sorting characters.
      # @see CocinaDisplay::TitleBuilder#sort_title
      # @return [String]
      def sort_title
        CocinaDisplay::TitleBuilder.sort_title(cocina_titles, catalog_links: catalog_links).first || "\u{10FFFF}"
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
    end
  end
end
