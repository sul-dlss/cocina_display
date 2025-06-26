require_relative "date"

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

        dates = cocina["structuredValue"].map { |sv| Date.from_cocina(sv) }
        start = dates.find(&:start?)
        stop = dates.find(&:end?)

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

      # The encoding value for the range.
      # Uses the start encoding, stop encoding, or top-level encoding in that order.
      # @see CocinaDisplay::Date#encoding
      # @return [String, nil]
      def encoding
        start&.encoding || stop&.encoding || super
      end

      # Is either date in the range qualified in any way?
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
        if start&.qualifier == stop&.qualifier
          qualifier = start&.qualifier || stop&.qualifier
          date = decoded_value
          return "[ca. #{date}]" if qualifier == "approximate"
          return "[#{date}?]" if qualifier == "questionable"
          return "[#{date}]" if qualifier == "inferred"

          date
        else
          "#{start&.qualified_value} - #{stop&.qualified_value}"
        end
      end
    end
  end
end
