# frozen_string_literal: true

require "edtf"
require "active_support"
require "active_support/core_ext/enumerable"
require "active_support/core_ext/object/blank"

require_relative "event"
require_relative "../utils"
require_relative "../marc_country_codes"
require_relative "../dates/date"
require_relative "../dates/date_range"

module CocinaDisplay
  module Events
    # Wrapper for Cocina events used to generate an imprint statement for display.
    class Imprint < Event
      # The entire imprint statement formatted as a string for display.
      # @return [String]
      def display_str
        place_pub = Utils.compact_and_join([place_str, publisher_str], delimiter: " : ")
        edition_place_pub = Utils.compact_and_join([edition_str, place_pub], delimiter: " - ")
        Utils.compact_and_join([edition_place_pub, date_str], delimiter: ", ")
      end

      # Were any of the dates encoded?
      # Used to detect which event(s) most likely represent the actual imprint(s).
      def date_encoding?
        dates.any?(&:encoding?)
      end

      private

      # The date portion of the imprint statement, comprising all unique dates.
      # @return [String]
      def date_str
        Utils.compact_and_join(unique_dates_for_display.map(&:qualified_value))
      end

      # The editions portion of the imprint statement, combining all edition notes.
      # @return [String]
      def edition_str
        Utils.compact_and_join(Janeway.enum_for("$.note[?@.type == 'edition'].value", cocina))
      end

      # The place of publication, combining all location values.
      # @return [String]
      def place_str
        Utils.compact_and_join(locations_for_display, delimiter: " : ")
      end

      # The publisher information, combining all name values for publishers.
      # @return [String]
      def publisher_str
        Utils.compact_and_join(publishers.map(&:display_name), delimiter: " : ")
      end

      # All publishers associated with this imprint.
      # @return [Array<CocinaDisplay::Contributor>]
      # @see CocinaDisplay::Contributor#publisher?
      def publishers
        contributors.filter(&:publisher?)
      end

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
        ranges.reject! { |range| unencoded_singles_dates.any? { |date| range.as_interval.include?(date) } }

        (singles + ranges).sort
      end

      # Filter locations to display according to predefined rules.
      # 1. Prefer unencoded locations (plain value) over encoded ones
      # 2. If no unencoded locations but there are MARC country codes, decode them
      # 3. Keep only unique locations after decoding
      def locations_for_display
        unencoded_locs, encoded_locs = locations.partition { |loc| loc.unencoded_value? }
        locs_for_display = unencoded_locs.presence || encoded_locs
        locs_for_display.map(&:display_str).compact_blank.uniq
      end
    end
  end
end
