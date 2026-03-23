module CocinaDisplay
  module Events
    # An event associated with an object, like publication.
    class Event
      include Comparable

      attr_reader :cocina

      # Initialize the event with Cocina event data.
      # @param cocina [Hash] Cocina structured data for a single event
      def initialize(cocina)
        @cocina = cocina
      end

      # Compare this {Event} to another {Event} using their {Date}s.
      # @note Also supports `event1.between?(event2, event3)` via {Comparable}.
      # @return [Integer, nil]
      def <=>(other)
        [dates] <=> [other.dates] if other.is_a?(Event)
      end

      # The display label for the event.
      # Uses "Imprint" if the event is likely to represent an imprint statement.
      # If the event consists solely of a date, uses the date's label.
      # Capitalizes the event's type, or its first date's type if untyped.
      # @return [String]
      def label
        return cocina["displayLabel"] if cocina["displayLabel"].present?
        return dates.map(&:label).first if date_only?

        type&.capitalize || date_types.first&.capitalize || "Event"
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
        types.include?(match_type)
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

      # True if this event is likely to represent an imprint.
      # @note Unencoded dates or no dates often indicate an imprint statement.
      # @return [Boolean]
      def imprint?
        contributors.present? &&
          locations.present? &&
          (has_type?("publication") || types.empty?) &&
          (dates.any? { |date| !date.encoding? } || dates.none?)
      end

      # All contributors associated with this event.
      # @return [Array<CocinaDisplay::Contributor>]
      def contributors
        @contributors ||= Array(cocina["contributor"]).map do |contributor|
          CocinaDisplay::Contributors::Contributor.new(contributor)
        end
      end

      # All locations associated with this event.
      # @return [Array<CocinaDisplay::Events::Location>]
      def locations
        @locations ||= Array(cocina["location"]).map do |location|
          CocinaDisplay::Events::Location.new(location)
        end
      end

      # All notes associated with this event.
      # @return [Array<CocinaDisplay::Events::Note>]
      def notes
        @notes ||= Array(cocina["note"]).map do |note|
          CocinaDisplay::Events::Note.new(note)
        end
      end

      # String representation of the event using date and location.
      # @return [String]
      # @example "John Doe, New York (State), 1999"
      def to_s
        Utils.compact_and_join([place_str, date_str], delimiter: ", ")
      end

      # Union of event's type and its date types.
      # Used for imprint detection and display decisions.
      # @return [Array<String>]
      def types
        [type, *date_types].compact
      end

      private

      # Does this event include no rendered information other than its date?
      # @note If true, the label will be "[type] date" instead of just "[type]".
      # @return [Boolean]
      def date_only?
        to_s == date_str
      end

      # The dates associated with this event that should be used for display.
      # Prefers encoded dates when there are duplicates.
      # @return [Array<CocinaDisplay::Dates::Date>]
      def display_dates
        # Choose a single date for each group with the same base value;
        # prefer encoded dates when there are duplicates.
        deduped_dates = dates.group_by(&:base_value).map do |base_value, group|
          if (encoded = group.filter(&:encoding?)).any?
            encoded.first
          else
            group.first
          end
        end

        # Remove any ranges that duplicate part of an encoded non-range date
        ranges, singles = deduped_dates.partition { |date| date.is_a?(CocinaDisplay::Dates::DateRange) }
        encoded_singles_dates = singles.filter(&:encoding?).flat_map(&:to_a)
        ranges.reject! { |date_range| encoded_singles_dates.any? { |date| date_range.as_range.include?(date) } }

        (singles + ranges).sort
      end

      # Dates associated with this event as a single string.
      # @return [String]
      def date_str
        display_dates.map(&:qualified_value).compact_blank.uniq.to_sentence
      end

      # Locations associated with this event as a single string.
      # @return [String]
      def place_str
        locations.map(&:to_s).compact_blank.uniq.join(", ")
      end
    end
  end
end
