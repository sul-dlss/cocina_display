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

      # The display label for the event.
      # Capitalizes the event's type, or its first date's type if untyped.
      # @return [String]
      def label
        cocina["displayLabel"].presence || type&.capitalize || date_types.first&.capitalize || "Event"
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

      # Were any of the dates encoded?
      # Used to detect which event(s) most likely represent the actual imprint(s).
      def date_encoding?
        dates.any?(&:encoding?)
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

      # String representation of the event using notes, dates, locations, and contributors.
      # Format is inspired by typical imprint statements for books.
      # @return [String]
      # @example "2nd ed. - New York : John Doe, 1999"
      def to_s
        place_contrib = Utils.compact_and_join([place_str, contributor_str], delimiter: " : ")
        note_place_contrib = Utils.compact_and_join([note_str, place_contrib], delimiter: " - ")
        Utils.compact_and_join([note_place_contrib, date_str], delimiter: ", ")
      end

      private

      # Filter dates for uniqueness using base value according to predefined rules.
      # 1. For a group of dates with the same base value, choose a single one
      # 2. Prefer unencoded dates over encoded ones when choosing a single date
      # 3. Remove date ranges that duplicate any unencoded non-range dates
      # @return [Array<CocinaDisplay::Dates::Date>]
      # @see CocinaDisplay::Dates::Date#base_value
      # @see https://consul.stanford.edu/display/chimera/MODS+display+rules#MODSdisplayrules-3b.%3CoriginInfo%3E
      def unique_dates_for_display
        # Choose a single date for each group with the same base value
        deduped_dates = dates.group_by(&:base_value).map do |base_value, group|
          if (unencoded = group.reject(&:encoding?)).any?
            unencoded.first
          else
            group.first
          end
        end

        # Remove any ranges that duplicate part of an unencoded non-range date
        ranges, singles = deduped_dates.partition { |date| date.is_a?(CocinaDisplay::Dates::DateRange) }
        unencoded_singles_dates = singles.reject(&:encoding?).flat_map(&:to_a)
        ranges.reject! { |date_range| unencoded_singles_dates.any? { |date| date_range.as_range.include?(date) } }

        (singles + ranges).sort
      end

      # Filter locations to display according to predefined rules.
      # 1. Prefer unencoded locations (plain value) over encoded ones
      # 2. If no unencoded locations but there are MARC country codes, decode them
      # 3. Keep only unique locations after decoding
      def locations_for_display
        unencoded_locs, encoded_locs = locations.partition { |loc| loc.unencoded_value? }
        locs_for_display = unencoded_locs.presence || encoded_locs
        locs_for_display.map(&:to_s).compact_blank.uniq
      end

      # The date portion of the imprint statement, comprising all unique dates.
      # @return [String]
      def date_str
        Utils.compact_and_join(unique_dates_for_display.map(&:qualified_value), delimiter: "; ")
      end

      # All notes associated with the event as a single string.
      # @return [String]
      def note_str
        Utils.compact_and_join(notes.map(&:to_s))
      end

      # All contributors associated with the event as a single string.
      # @return [String]
      def contributor_str
        Utils.compact_and_join(contributors.map(&:display_name), delimiter: " : ")
      end

      # The place of publication, combining all location values.
      # @return [String]
      def place_str
        Utils.compact_and_join(locations_for_display, delimiter: " : ")
      end
    end
  end
end
