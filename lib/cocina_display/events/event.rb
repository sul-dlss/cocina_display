require_relative "location"
require_relative "../dates/date"
require_relative "../contributor"

module CocinaDisplay
  module Events
    # An event associated with an object, like publication.
    class Event
      attr_reader :cocina

      # Initialize the event with Cocina event data.
      # @param cocina [Hash] Cocina structured data for a single event
      def initialize(cocina)
        @cocina = cocina
      end

      # Express the event as an Imprint object.
      # This adds additional methods for display and formatting.
      # @return [CocinaDisplay::Events::Imprint]
      def as_imprint
        CocinaDisplay::Events::Imprint.new(cocina)
      end

      # The declared type of the event, like "publication" or "creation".
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#event-types
      # @note This can differ from the contained date types.
      # @return [String, nil]
      def type
        cocina["type"]
      end

      # All types of dates associated with this event.
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#event-date-types
      # @note This can differ from the top-level event type.
      # @return [Array<String>]
      def date_types
        dates.map(&:type).uniq
      end

      # True if either the event type or any date type matches the given type.
      # @param match_type [String] The type to check against
      # @return [Boolean]
      def has_type?(match_type)
        [type, *date_types].compact.include?(match_type)
      end

      # True if the event or its dates have any of the provided types.
      # @param match_types [Array<String>] The types to check against
      # @return [Boolean]
      def has_any_type?(*match_types)
        match_types.any? { |type| has_type?(type) }
      end

      # All dates associated with this event.
      # Ignores known unparsable date values like "9999".
      # If the date is untyped, uses this event's type as the date type.
      # @note The date types may differ from the underlying event type.
      # @return [Array<CocinaDisplay::Dates::Date>]
      def dates
        @dates ||= Array(cocina["date"]).filter_map do |date|
          CocinaDisplay::Dates::Date.from_cocina(date)
        end.filter(&:parsable?).map do |date|
          date.type ||= type
          date
        end
      end

      # All contributors associated with this event.
      # @return [Array<CocinaDisplay::Contributor>]
      def contributors
        @contributors ||= Array(cocina["contributor"]).map do |contributor|
          CocinaDisplay::Contributor.new(contributor)
        end
      end

      # All locations associated with this event.
      # @return [Array<CocinaDisplay::Events::Location>]
      def locations
        @locations ||= Array(cocina["location"]).map do |location|
          CocinaDisplay::Events::Location.new(location)
        end
      end
    end
  end
end
