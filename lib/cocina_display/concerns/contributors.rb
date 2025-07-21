require_relative "../contributor"

module CocinaDisplay
  module Concerns
    # Methods for finding and formatting names for contributors
    module Contributors
      # The main contributor's name, formatted for display.
      # @param with_date [Boolean] Include life dates, if present
      # @return [String]
      # @return [nil] if no main contributor is found
      # @example
      #   record.main_contributor_name #=> "Smith, John"
      # @example with date
      #   record.main_contributor_name(with_date: true) #=> "Smith, John, 1970-2020"
      def main_contributor_name(with_date: false)
        main_contributor&.display_name(with_date: with_date)
      end

      # All contributor names except the main one, formatted for display.
      # @param with_date [Boolean] Include life dates, if present
      # @return [Array<String>]
      def additional_contributor_names(with_date: false)
        additional_contributors.map { |c| c.display_name(with_date: with_date) }
      end

      # All names of publishers, formatted for display.
      # @return [Array<String>]
      def publisher_names
        publisher_contributors.map(&:display_name)
      end

      # All names of authors who are people, formatted for display.
      # @param with_date [Boolean] Include life dates, if present
      # @return [Array<String>]
      def person_contributor_names(with_date: false)
        contributors.filter(&:person?).map { |c| c.display_name(with_date: with_date) }
      end

      # All names of non-person contributors, formatted for display.
      # This includes organizations, conferences, families, etc.
      # @return [Array<String>]
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#contributor-types
      def impersonal_contributor_names
        contributors.reject(&:person?).map(&:display_name)
      end

      # All names of contributors that are organizations, formatted for display.
      # @return [Array<String>]
      def organization_contributor_names
        contributors.filter(&:organization?).map(&:display_name)
      end

      # All names of contributors that are conferences, formatted for display.
      # @return [Array<String>]
      def conference_contributor_names
        contributors.filter(&:conference?).map(&:display_name)
      end

      # A hash mapping role names to the names of contributors with that role.
      # @param with_date [Boolean] Include life dates, if present
      # @return [Hash<String, Array<String>>]
      def contributor_names_by_role(with_date: false)
        contributors.each_with_object({}) do |contributor, hash|
          contributor.roles.each do |role|
            hash[role.display_str] ||= []
            hash[role.display_str] << contributor.display_name(with_date: with_date)
          end
        end
      end

      # A string value for sorting by contributor that sorts missing values last.
      # Ignores punctuation and leading/trailing spaces.
      # @return [String]
      def sort_contributor_name
        (main_contributor&.display_name || "\u{10FFFF}").gsub(/[[:punct:]]*/, "").strip
      end

      # All contributors for the object, including authors, editors, etc.
      # @return [Array<Contributor>]
      def contributors
        @contributors ||= path("$.description.contributor.*").map { |c| Contributor.new(c) }
      end

      # All contributors with a "publisher" role.
      # @return [Array<Contributor>]
      # @see Contributor#publisher?
      def publisher_contributors
        contributors.filter(&:publisher?)
      end

      # Object representing the main contributor.
      # Selected according to the following rules:
      # 1. If there are contributors marked as primary, use the first one.
      # 2. If there are no primary contributors, use the first contributor with no role.
      # 3. If there are no contributors without a role, use the first contributor.
      # @return [Contributor]
      # @return [nil] if there are no contributors at all
      def main_contributor
        contributors.find(&:primary?).presence || contributors.find { |c| !c.role? }.presence || contributors.first
      end

      # All contributors except the main one.
      # @return [Array<Contributor>]
      def additional_contributors
        return [] if contributors.empty? || contributors.one?
        contributors - [main_contributor]
      end
    end
  end
end
