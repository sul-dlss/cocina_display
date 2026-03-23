module CocinaDisplay
  module Events
    # An imprint statement associated with an object.
    class Imprint < Event
      # Imprints are labelled "Imprint" unless overridden by a displayLabel.
      # @return [String]
      def label
        cocina["displayLabel"].presence || "Imprint"
      end

      # Imprint statement for a book, formatted using typical conventions.
      # @return [String]
      # @example "2nd ed. - New York : John Doe, 1999"
      def to_s
        place_contrib = Utils.compact_and_join([place_str, contributor_str], delimiter: " : ")
        note_place_contrib = Utils.compact_and_join([edition_note_str, place_contrib], delimiter: " - ")
        Utils.compact_and_join([note_place_contrib, date_str, copyright_note_str], delimiter: ", ")
      end

      private

      # Filter dates for uniqueness using base value according to predefined rules.
      # 1. For a group of dates with the same base value, choose a single one
      # 2. Prefer unencoded dates over encoded ones when choosing a single date
      # 3. Remove date ranges that duplicate any unencoded non-range dates
      # @return [Array<CocinaDisplay::Dates::Date>]
      # @see CocinaDisplay::Dates::Date#base_value
      # @see https://consul.stanford.edu/display/chimera/MODS+display+rules#MODSdisplayrules-3b.%3CoriginInfo%3E
      def display_dates
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
      # @return [Array<String>]
      def display_locations
        unencoded_locs, encoded_locs = locations.partition { |loc| loc.unencoded_value? }
        locs_for_display = unencoded_locs.presence || encoded_locs
        locs_for_display.map(&:to_s).compact_blank.uniq
      end

      # Dates associated with this event as a single string.
      # @return [String]
      def date_str
        Utils.compact_and_join(display_dates.map(&:to_s), delimiter: "; ")
      end

      # Edition notes associated with the event as a single string.
      # @return [String]
      def edition_note_str
        Utils.compact_and_join(notes.filter { |note| note.type == "edition" }.map(&:to_s), delimiter: ", ")
      end

      # Copyright notes associated with the event as a single string.
      # @return [String]
      def copyright_note_str
        Utils.compact_and_join(notes.filter { |note| note.type == "copyright statement" }.map(&:to_s), delimiter: ", ")
      end

      # All contributors associated with the event as a single string.
      # @return [String]
      def contributor_str
        Utils.compact_and_join(contributors.map(&:display_name), delimiter: " : ")
      end

      # The place of publication, combining all location values.
      # @return [String]
      def place_str
        Utils.compact_and_join(display_locations, delimiter: " : ")
      end
    end
  end
end
