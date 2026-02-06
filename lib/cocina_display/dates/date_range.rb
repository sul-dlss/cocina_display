module CocinaDisplay
  module Dates
    # A date range parsed from Cocina structuredValues.
    class DateRange < Date
      attr_reader :start, :stop

      # Construct a DateRange from Cocina hash with structuredValue.
      # @param cocina [Hash] Cocina date data containing structuredValue
      # @return [CocinaDisplay::DateRange]
      # @return [nil] if no parsable start or stop dates are found
      def self.from_cocina(cocina)
        return unless cocina["structuredValue"].present?

        # Create the individual dates; if no encoding/type declared give them
        # top-level encoding/type
        dates = cocina["structuredValue"].map do |sv|
          sv["encoding"] ||= cocina["encoding"]
          date = Date.from_cocina(sv)
          date.type ||= cocina["type"]
          date
        end

        # Ensure we have at least a start or a stop
        start = dates.find(&:start?)
        stop = dates.find(&:end?)
        return unless start || stop

        DateRange.new(cocina, start: start, stop: stop)
      end

      # Create a new date range using two CocinaDisplay::Date objects.
      # @param cocina [Hash] Cocina date data containing structuredValue
      # @param start [CocinaDisplay::Date, nil] The start date of the range.
      # @param stop [CocinaDisplay::Date, nil] The end date of the range.
      # @return [CocinaDisplay::DateRange]
      def initialize(cocina, start: nil, stop: nil)
        @cocina = cocina
        @start = start
        @stop = stop
        @type = cocina["type"]
      end

      # The values of the start and stop dates as an array.
      # @see CocinaDisplay::Date#value
      # @return [Array<String>]
      def value
        [start&.value, stop&.value]
      end

      # Key used to sort this date range. Respects BCE/CE ordering and precision.
      # Ranges are sorted first by their start date, then by their stop date.
      # @see CocinaDisplay::Date#sort_key
      # @return [String]
      def sort_key
        [start&.sort_key, stop&.sort_key].join(" - ")
      end

      # Base values of start/end as single string. Used for comparison/deduping.
      # @note This is important for uniqueness checks in Imprint display.
      # @return [String]
      def base_value
        "#{@start&.base_value}-#{@stop&.base_value}"
      end

      # The encoding value for the range.
      # Uses the start encoding, stop encoding, or top-level encoding in that order.
      # @see CocinaDisplay::Date#encoding
      # @return [String, nil]
      def encoding
        start&.encoding || stop&.encoding || super
      end

      # The qualifier for the entire range.
      # If both qualifiers match, uses that qualifier. If both are empty, falls
      # back to the top level qualifier, if any.
      # @see CocinaDisplay::Date#qualifier
      # @return [String, nil]
      def qualifier
        if start&.qualifier == stop&.qualifier
          start&.qualifier || stop&.qualifier || super
        end
      end

      # Is either date in the range, or the range itself, qualified?
      # @see CocinaDisplay::Date#qualified?
      # @return [Boolean]
      def qualified?
        start&.qualified? || stop&.qualified? || super
      end

      # Is either date in the range marked as primary?
      # @see CocinaDisplay::Date#primary?
      # @return [Boolean]
      def primary?
        start&.primary? || stop&.primary? || super
      end

      # Was either date in the range successfully parsed?
      # @see CocinaDisplay::Date#parsed_date?
      # @return [Boolean]
      def parsed_date?
        start&.parsed_date? || stop&.parsed_date? || false
      end

      # False if both dates in the range have a known unparsable value like "9999".
      # @see CocinaDisplay::Date#parsable?
      # @return [Boolean]
      def parsable?
        start&.parsable? || stop&.parsable? || false
      end

      # Decoded version of the range, if it was encoded. Strips leading zeroes.
      # @see CocinaDisplay::Date#decoded_value
      # @return [String]
      def decoded_value(**kwargs)
        [
          start&.decoded_value(**kwargs),
          stop&.decoded_value(**kwargs)
        ].uniq.join(" - ")
      end

      # Decoded range with "BCE" or "CE" and qualifier markers applied.
      # @see CocinaDisplay::Date#qualified_value
      # @return [String]
      def qualified_value
        if qualifier
          case qualifier
          when "approximate"
            "[ca. #{decoded_value}]"
          when "questionable"
            "[#{decoded_value}?]"
          when "inferred"
            "[#{decoded_value}]"
          end
        else
          "#{start&.qualified_value} - #{stop&.qualified_value}"
        end
      end

      # Earliest possible date encoded in data, respecting unspecified/imprecise info.
      # @return [Date]
      # @return [nil] if open start
      def earliest_date
        start&.earliest_date
      end

      # Latest possible date encoded in data, respecting unspecified/imprecise info.
      # @return [Date]
      # @return [nil] if open-ended range
      def latest_date
        stop&.latest_date
      end

      # Express the range as an EDTF::Interval between the start and stop dates.
      # @return [EDTF::Interval]
      def as_interval
        interval_start = start&.date&.edtf || "open"
        interval_stop = stop&.date&.edtf || "open"
        ::Date.edtf("#{interval_start}/#{interval_stop}")
      end

      # Array of all individual {Date}s that are described by the data.
      # @note Output dates will have the same precision as the input date (e.g. year vs day).
      # @note {EDTF::Set}s can be disjoint ranges; unlike {#as_range} this method will respect any gaps.
      # @return [Array<Date>]
      def to_a
        start_dates = start&.to_a || []
        stop_dates = stop&.to_a || []

        return [] if start_dates.empty? && stop_dates.empty?
        return as_range.to_a if start_dates.one? && stop_dates.one? || stop_dates.empty?

        [start_dates, stop_dates].flatten.sort.uniq
      end
    end
  end
end
