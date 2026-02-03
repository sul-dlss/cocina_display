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
        return unless (date = pub_date(ignore_qualified: ignore_qualified))

        if date.is_a? CocinaDisplay::Dates::DateRange
          date = date.start&.known? ? date.start : date.stop
        end

        return unless date&.known?
        return date.date.from if date.date.is_a?(EDTF::Interval)

        date.date
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

      # The range of preferred publication years as an array of integers.
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [Array<Integer>, nil]
      # @note 6 BCE will appear as -5; 4 CE will appear as 4.
      def pub_year_int_range(ignore_qualified: false)
        date = pub_date(ignore_qualified: ignore_qualified)
        return unless date

        date.to_a.map(&:year).compact.uniq.sort
      end

      # String for displaying the earliest preferred publication year or range.
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [String, nil]
      # @example Year range
      #  CocinaRecord.fetch('bb099mt5053').pub_year_str #=> "1932 - 2012"
      def pub_year_str(ignore_qualified: false)
        date = pub_date(ignore_qualified: ignore_qualified)
        return unless date

        date.decoded_value(allowed_precisions: [:year, :decade, :century])
      end

      # String for displaying the imprint statement(s).
      # @return [String, nil]
      # @see CocinaDisplay::Imprint#to_s
      # @example bt553vr2845
      # "New York : Meridian Book, 1993, c1967"
      def imprint_str
        imprint_events.map(&:to_s).compact_blank.join("; ")
      end

      # List of places of publication as strings.
      # Considers locations for all publication, creation, and capture events.
      # @return [Array<String>]
      def publication_places
        publication_events.flat_map { |event| event.locations.map(&:to_s) }.compact_blank.uniq
      end

      # List of countries of publication as strings.
      # Considers locations for all publication, creation, and capture events.
      # @return [Array<String>]
      def publication_countries
        publication_events.flat_map { |event| event.locations.map(&:country_name) }.compact_blank.uniq
      end

      # All root level events associated with the object.
      # @return [Array<CocinaDisplay::Events::Event>]
      def events
        @events ||= path("$.description.event.*").map { |event| CocinaDisplay::Events::Event.new(event) }
      end

      # The adminMetadata creation event (When was it was deposited?)
      # @return <CocinaDisplay::Events::Event>
      def admin_creation_event
        @admin_events ||= path("$.description.adminMetadata.event[?(@.type==\"creation\")]").map { |event| CocinaDisplay::Events::Event.new(event) }.first
      end

      # All events that could be used to select a publication date.
      # Includes publication, creation, and capture events.
      # Considers event types as well as date types if the event is untyped.
      # @return [Array<CocinaDisplay::Events::Event>]
      def publication_events
        events.filter { |event| event.has_any_type?("publication", "creation", "capture") }
      end

      # Array of CocinaDisplay::Imprint objects for all relevant Cocina events.
      # Considers publication, creation, capture, and copyright events.
      # Considers event types as well as date types if the event is untyped.
      # Prefers events where the date was not encoded, if any.
      # @return [Array<CocinaDisplay::Imprint>] The list of Imprint objects
      def imprint_events
        imprints = events.filter do |event|
          event.has_any_type?("publication", "creation", "capture", "copyright")
        end.map do |event|
          CocinaDisplay::Events::Imprint.new(event.cocina)
        end

        imprints.reject(&:date_encoding?).presence || imprints
      end

      # All dates associated with the object via an event.
      # @return [Array<CocinaDisplay::Dates::Date>]
      def event_dates
        @event_dates ||= events.flat_map(&:dates)
      end

      # DisplayData for all notes associated with events.
      # @return [Array<CocinaDisplay::DisplayData>]
      def event_note_display_data
        CocinaDisplay::DisplayData.from_objects(events.flat_map(&:notes))
      end

      # DisplayData for all dates associated with events.
      # @return [Array<CocinaDisplay::DisplayData>]
      def event_date_display_data
        CocinaDisplay::DisplayData.from_objects(event_dates)
      end

      # The earliest preferred publication date as a CocinaDisplay::Dates::Date object.
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [CocinaDisplay::Dates::Date] The earliest preferred date
      # @return [nil] if no dates are left after filtering
      def pub_date(ignore_qualified: false)
        pub_event_dates = event_dates.filter { |date| date.type == "publication" }
        creation_event_dates = event_dates.filter { |date| date.type == "creation" }
        capture_event_dates = event_dates.filter { |date| date.type == "capture" }

        [pub_event_dates, creation_event_dates, capture_event_dates].flat_map do |dates|
          earliest_preferred_date(dates, ignore_qualified: ignore_qualified)
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
