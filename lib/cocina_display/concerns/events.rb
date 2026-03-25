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
      def pub_year_ints(ignore_qualified: false)
        date = pub_date(ignore_qualified: ignore_qualified)
        return unless date

        date.to_a.map(&:year).compact.uniq.sort
      end

      # String for displaying the earliest preferred publication year or range.
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [String, nil]
      # @example Year with month and day, 2024-08-21 (vc109xd3118)
      #   "2024"
      # @example Approximate year range, [ca. 1932 - 2012] (bb099mt5053)
      #   "1932 - 2012"
      # @example BCE year range, [ca. 3500 BCE] - 3101 BCE (yv690gn5376)
      #   "3500 BCE - 3101 BCE"
      # @example Unencoded string, 'about 933'
      #   "933 CE"
      # @example Not parsable, 'invalid-date'
      #   nil
      def pub_year_str(ignore_qualified: false)
        date = pub_date(ignore_qualified: ignore_qualified)
        return unless date&.parsed_date?

        date.decoded_value(allowed_precisions: [:year, :decade, :century])
      end

      # String for sorting lexicographically by publication date.
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # @note BCE dates have special handling; see Date#sort_key for details.
      # @param ignore_qualified [Boolean] Reject qualified dates (e.g. approximate)
      # @return [String, nil]
      # @example Year with month and day, 2024-08-21 (vc109xd3118)
      #   "20240821"
      # @example Approximate year range, [ca. 1932 - 2012] (bb099mt5053)
      #   "1932000020120000"
      # @example BCE year range, [ca. 3500 BCE] - 3101 BCE (yv690gn5376)
      #   "-564990000-568980000"
      def pub_date_sort_str(ignore_qualified: false)
        pub_date(ignore_qualified: ignore_qualified)&.sort_key
      end

      # String for displaying the publication date.
      # Considers publication, creation, and capture dates in that order.
      # Prefers dates marked as primary and those with a declared encoding.
      # If not encoded, returns the original string value from the Cocina.
      # @return [String, nil]
      # @example w3cdtf encoded year with month and day (vc109xd3118)
      #   "August 21, 2024"
      # @example w3cdtf encoded approximate year range (bb099mt5053)
      #   "[ca. 1932 - 2012]"
      # @example Unencoded string, 'about 933'
      #   "about 933"
      # @example Not parsable, 'invalid-date'
      #   "invalid-date"
      def pub_date_str
        pub_date&.to_s
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
        events.filter(&:imprint?)
      end

      # All dates associated with the object via an event.
      # @return [Array<CocinaDisplay::Dates::Date>]
      def event_dates
        @event_dates ||= events.flat_map(&:dates)
      end

      # DisplayData for all events associated with the object.
      # @return [Array<CocinaDisplay::DisplayData>]
      def event_display_data
        CocinaDisplay::DisplayData.from_objects(events)
      end

      # DisplayData for issuance, copyright, and other notes associated with events.
      # @return [Array<CocinaDisplay::DisplayData>]
      def event_note_display_data
        CocinaDisplay::DisplayData.from_objects(events.flat_map(&:notes))
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
