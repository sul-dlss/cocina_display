require_relative "../contributor"

module CocinaDisplay
  module Concerns
    # Methods for finding and formatting names for contributors
    module Contributors
      # The main author's name, formatted for display.
      # @param with_date [Boolean] Include life dates, if present
      # @return [String]
      # @return [nil] if no main author is found
      # @example
      #   record.main_author #=> "Smith, John"
      # @example with date
      #   record.main_author(with_date: true) #=> "Smith, John, 1970-2020"
      def main_author(with_date: false)
        main_author_contributor&.display_name(with_date: with_date)
      end

      # All author names except the main one, formatted for display.
      # @param with_date [Boolean] Include life dates, if present
      # @return [Array<String>]
      def additional_authors(with_date: false)
        additional_author_contributors.map { |c| c.display_name(with_date: with_date) }
      end

      # All names of authors who are people, formatted for display.
      # @param with_date [Boolean] Include life dates, if present
      # @return [Array<String>]
      def person_authors(with_date: false)
        authors.filter(&:person?).map { |c| c.display_name(with_date: with_date) }
      end

      # All names of non-person authors, formatted for display.
      # This includes organizations, conferences, families, etc.
      # @return [Array<String>]
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#contributor-types
      def impersonal_authors
        authors.reject(&:person?).map(&:display_name)
      end

      # All names of authors that are organizations, formatted for display.
      # @return [Array<String>]
      def organization_authors
        authors.filter(&:organization?).map(&:display_name)
      end

      # All names of authors that are conferences, formatted for display.
      # @return [Array<String>]
      def conference_authors
        authors.filter(&:conference?).map(&:display_name)
      end

      # A string value for sorting by author that sorts missing values last.
      # Ignores punctuation and leading/trailing spaces.
      # @return [String]
      def sort_author
        (main_author_contributor&.display_name || "\u{10FFFF}").gsub(/[[:punct:]]*/, "").strip
      end

      private

      # All contributors for the object, including authors, editors, etc.
      # @return [Array<Contributor>]
      def contributors
        @contributors ||= path("$.description.contributor[*]").map { |c| Contributor.new(c) }
      end

      # All contributors with a "creator" or "author" role.
      # @return [Array<Contributor>]
      # @see Contributor#author?
      def authors
        contributors.filter(&:author?)
      end

      # Contributor object representing the primary author.
      # Selected according to the following rules:
      # 1. If there is a primary author or creator, use that.
      # 2. If there are no primary authors or creators, use the first one.
      # 3. If there are none at all, use the first contributor without any role.
      # @return [Contributor]
      # @return [nil] if no suitable contributor is found
      def main_author_contributor
        authors.find(&:primary?).presence || authors.first || contributors.find { |c| !c.role? }.presence
      end

      # All author/creator contributors except the main one.
      # @return [Array<Contributor>]
      def additional_author_contributors
        return [] if authors.empty? || authors.one? || !authors.include?(main_author_contributor)
        authors - [main_author_contributor]
      end
    end
  end
end
