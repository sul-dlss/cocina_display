require_relative "../dates/date"
require_relative "../dates/date_range"
require_relative "../imprint"

module CocinaDisplay
  module Concerns
    module Events
      # The earliest preferred publication date as a Date object.
      # If the date was a range or interval, uses the start (or end if no start).
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [Date, nil]
      # @see https://github.com/inukshuk/edtf-ruby
      def pub_date_edtf(ignore_qualified: false)
        date = pub_date(ignore_qualified: ignore_qualified)
        return unless date

        if date.is_a? CocinaDisplay::Dates::DateRange
          date = date.start || date.stop
        end

        edtf_date = date.date
        return unless edtf_date

        if edtf_date.is_a? EDTF::Interval
          edtf_date.from
        else
          edtf_date
        end
      end

      # The earliest preferred publication year as an integer.
      # If the date was a range or interval, uses the start (or end if no start).
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [Integer, nil]
      # @note 6 BCE will return -5; 4 CE will return 4.
      def pub_year_int(ignore_qualified: false)
        pub_date_edtf(ignore_qualified: ignore_qualified)&.year
      end

      # String for displaying the earliest preferred publication year or range.
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [String, nil]
      # @example Year range
      #  CocinaRecord.fetch('bb099mt5053').pub_year_display_str #=> "1932 - 2012"
      def pub_year_display_str(ignore_qualified: false)
        date = pub_date(ignore_qualified: ignore_qualified)
        return unless date

        date.decoded_value(allowed_precisions: [:year, :decade, :century])
      end

      # String for displaying the imprint statement(s).
      # @return [String, nil]
      # @see CocinaDisplay::Imprint#display_str
      # @example
      #   CocinaRecord.fetch('bt553vr2845').imprint_display_str #=> "New York : Meridian Book, 1993, c1967"
      def imprint_display_str
        imprints.map(&:display_str).compact_blank.join("; ")
      end

      private

      # Event dates as an array of CocinaDisplay::Dates::Date objects.
      # If type is provided, keep dates with a matching event type OR date type.
      # @param type [Symbol, nil] Filter by event type (e.g. :publication).
      # @return [Array<CocinaDisplay::Dates::Date>] The list of event dates
      def event_dates(type: nil)
        filter_expr = type.present? ? "?match(@.type, \"#{type}\")" : "*"

        Enumerator::Chain.new(
          path("$.description.event[*].date[#{filter_expr}]"),
          path("$.description.event[#{filter_expr}].date[*]")
        ).uniq.map do |date|
          CocinaDisplay::Dates::Date.from_cocina(date)
        end
      end

      # Array of CocinaDisplay::Imprint objects for all relevant Cocina events.
      # Considers publication, creation, capture, and copyright events.
      # Considers event types as well as date types if the event is untyped.
      # Prefers events where the date was not encoded, if any.
      # @return [Array<CocinaDisplay::Imprint>] The list of Imprint objects
      def imprints
        filter_expr = "\"(publication|creation|capture|copyright)\""

        imprints = Enumerator::Chain.new(
          path("$.description.event[?match(@.type, #{filter_expr})]"),
          path("$.description.event[?@.date[?match(@.type, #{filter_expr})]]")
        ).uniq.map do |event|
          CocinaDisplay::Imprint.new(event)
        end

        imprints.reject(&:date_encoding?).presence || imprints
      end

      # The earliest preferred publication date as a CocinaDisplay::Dates::Date object.
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [CocinaDisplay::Dates::Date] The earliest preferred date
      # @return [nil] if no dates are left after filtering
      def pub_date(ignore_qualified: false)
        [:publication, :creation, :capture].map do |type|
          earliest_preferred_date(event_dates(type: type), ignore_qualified: ignore_qualified)
        end.compact.first
      end

      # Choose the earliest, best date from a provided list of event dates.
      # Rules to consider:
      # 1. Reject any dates that were not parsed.
      # 2. If `ignore_qualified` is true, reject any qualified dates.
      # 3. If there are any primary dates, prefer those dates.
      # 4. If there are any encoded dates, prefer those dates.
      # 5. From whatever is left, choose the earliest date.
      # @param dates [Array<CocinaDisplay::Dates::Date>] The list of dates
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [CocinaDisplay::Dates::Date] The earliest preferred date
      # @return [nil] if no dates are left after filtering
      def earliest_preferred_date(dates, ignore_qualified: false)
        return nil if dates.empty?

        dates.filter!(&:parsed_date?)
        dates.reject!(&:approximate?) if ignore_qualified
        dates = dates.filter(&:primary?).presence || dates
        dates = dates.filter(&:encoding?).presence || dates

        dates.min
      end
    end
  end
end
