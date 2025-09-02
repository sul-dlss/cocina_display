require "edtf"

require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/integer/inflections"

module CocinaDisplay
  module Dates
    # A date to be converted to a Date object.
    class Date
      # List of values that we shouldn't even attempt to parse.
      UNPARSABLE_VALUES = ["0000-00-00", "9999", "uuuu", "[uuuu]"].freeze

      def self.notifier
        CocinaDisplay.notifier
      end

      # Construct a Date from parsed Cocina data.
      # @param cocina [Hash] Cocina date data
      # @return [CocinaDisplay::Date]
      def self.from_cocina(cocina)
        # Create a DateRange instead if structuredValue(s) are present
        return DateRange.from_cocina(cocina) if cocina["structuredValue"].present?

        # If an encoding was declared, use it. Cocina validates this
        case cocina.dig("encoding", "code")
        when "w3cdtf"
          W3cdtfFormat.new(cocina)
        when "iso8601"
          Iso8601Format.new(cocina)
        when "marc"
          MarcFormat.new(cocina)
        when "edtf"
          EdtfFormat.new(cocina)
        else  # No declared encoding, or unknown encoding
          value = cocina["value"]

          # Don't bother with weird unparseable values
          date_class = UnparseableDate if value =~ /\p{Hebrew}/ || value =~ /^-/

          # Try to match against known date formats using their regexes
          # Order matters here; more specific formats should be checked first
          date_class ||= [
            UndeclaredEdtfFormat,
            MMDDYYYYFormat,
            MMDDYYFormat,
            YearRangeFormat,
            DecadeAsYearDashFormat,
            DecadeStringFormat,
            EmbeddedBCYearFormat,
            EmbeddedYearFormat,
            EmbeddedThreeDigitYearFormat,
            EmbeddedYearWithBracketsFormat,
            MysteryCenturyFormat,
            CenturyFormat,
            RomanNumeralCenturyFormat,
            RomanNumeralYearFormat,
            OneOrTwoDigitYearFormat
          ].find { |klass| klass.supports?(value) }

          # If no specific format matched, use the base class
          date_class ||= CocinaDisplay::Dates::Date

          date_class.new(cocina)
        end
      end

      # Parse a string to a Date object according to the given encoding.
      # Delegates to the parser subclass {normalize_to_edtf} method.
      # @param value [String] the date value to parse
      # @return [Date]
      # @return [nil] if the date is blank or invalid
      def self.parse_date(value)
        ::Date.edtf(normalize_to_edtf(value))
      end

      # Apply any encoding-specific munging or text extraction logic.
      # @note This is the "fallback" version when no other parser matches.
      # @param value [String] the date value to modify
      # @return [String]
      def self.normalize_to_edtf(value)
        unless value
          notifier&.notify("Invalid date value: #{value}")
          return
        end

        sanitized = value.gsub(/^[\[]+/, "").gsub(/[\.\]]+$/, "")
        sanitized = value.rjust(4, "0") if /^\d{3}$/.match?(value)

        sanitized
      end

      attr_reader :cocina, :date

      # The type of this date, if any, such as "creation", "publication", etc.
      # @return [String, nil]
      attr_accessor :type

      # The encoding name of this date, if specified.
      # @example "iso8601"
      # @return [String, nil]
      attr_accessor :encoding

      def initialize(cocina)
        @cocina = cocina
        @date = self.class.parse_date(cocina["value"])
        @type = cocina["type"] unless ["start", "end"].include?(cocina["type"])
        @encoding = cocina.dig("encoding", "code")
      end

      # Compare this date to another {Date} or {DateRange} using its {sort_key}.
      def <=>(other)
        sort_key <=> other.sort_key if other.is_a?(Date) || other.is_a?(DateRange)
      end

      # The text representation of the date, as stored in Cocina.
      # @return [String]
      def value
        cocina["value"]
      end

      # The qualifier for this date, if any, such as "approximate", "inferred", etc.
      # @return [String, nil]
      def qualifier
        cocina["qualifier"]
      end

      # Does this date have a qualifier? E.g. "approximate", "inferred", etc.
      # @return [Boolean]
      def qualified?
        qualifier.present?
      end

      # Was an encoding declared for this date?
      # @return [Boolean]
      def encoding?
        encoding.present?
      end

      # Is this the start date in a range?
      # @return [Boolean]
      # @note The Cocina will mark start dates with "type": "start".
      def start?
        cocina["type"] == "start"
      end

      # Is this the end date in a range?
      # @return [Boolean]
      # @note The Cocina will mark end dates with "type": "end".
      def end?
        cocina["type"] == "end"
      end

      # Was the date marked as approximate?
      # @return [Boolean]
      def approximate?
        qualifier == "approximate"
      end

      # Was the date marked as inferred?
      # @return [Boolean]
      def inferred?
        qualifier == "inferred"
      end

      # Was the date marked as approximate?
      # @return [Boolean]
      def questionable?
        qualifier == "questionable"
      end

      # Was the date marked as primary?
      # @note In MODS XML, this corresponds to the +keyDate+ attribute.
      # @return [Boolean]
      def primary?
        cocina["status"] == "primary"
      end

      # Is the value present and not a known unparsable value like "9999"?
      # @return [Boolean]
      def parsable?
        value.present? && !UNPARSABLE_VALUES.include?(value)
      end

      # Did we successfully parse a date from the Cocina data?
      # @return [Boolean]
      def parsed_date?
        date.present?
      end

      # How precise is the parsed date information?
      # @return [Symbol] :year, :month, :day, :decade, :century, or :unknown
      def precision
        return :unknown unless date_range || date

        if date_range.is_a? EDTF::Century
          :century
        elsif date_range.is_a? EDTF::Decade
          :decade
        elsif date.is_a? EDTF::Season
          :month
        elsif date.is_a? EDTF::Interval
          date.precision
        else
          case date.precision
          when :month
            date.unspecified.unspecified?(:month) ? :year : :month
          when :day
            d = date.unspecified.unspecified?(:day) ? :month : :day
            date.unspecified.unspecified?(:month) ? :year : d
          else
            date.precision
          end
        end
      end

      # Used to sort BCE dates correctly in lexicographic order.
      BCE_CHAR_SORT_MAP = {"0" => "9", "1" => "8", "2" => "7", "3" => "6", "4" => "5", "5" => "4", "6" => "3", "7" => "2", "8" => "1", "9" => "0"}.freeze

      # Key used to sort this date. Respects BCE/CE ordering and precision.
      # @return [String]
      def sort_key
        # Even if not parsed, we might need to sort it for display later
        return "" unless parsed_date?

        # Use the start of an interval for sorting
        sort_date = date.is_a?(EDTF::Interval) ? date.from : date

        # Get the parsed year, month, and day values
        year, month, day = if sort_date.respond_to?(:values)
          sort_date.values
        else
          [sort_date.year, nil, nil]
        end

        # Format year into sortable string
        year_str = if year > 0
          # for CE dates, we can just pad them out to 4 digits and sort normally...
          year.to_s.rjust(4, "0")
        else
          #  ... but for BCE, because we're sorting lexically, we need to invert the digits (replacing 0 with 9, 1 with 8, etc.),
          #  we prefix it with a hyphen (which will sort before any digit) and the number of digits (also inverted) to get
          # it to sort correctly.
          inverted_year = year.abs.to_s.chars.map { |c| BCE_CHAR_SORT_MAP[c] }.join
          length_prefix = BCE_CHAR_SORT_MAP[inverted_year.to_s.length.to_s]
          "-#{length_prefix}#{inverted_year}"
        end

        # Format month and day into sortable strings, pad to 2 digits
        month_str = month ? month.to_s.rjust(2, "0") : "00"
        day_str = day ? day.to_s.rjust(2, "0") : "00"

        # Join into a sortable string; add hyphens so decade/century sort first
        case precision
        when :decade
          [year_str[0...-1], "-", month_str, day_str].join
        when :century
          [year_str[0...-2], "--", month_str, day_str].join
        else
          [year_str, month_str, day_str].join
        end
      end

      # Value reduced to digits and hyphen. Used for comparison/deduping.
      # @note This is important for uniqueness checks in Imprint display.
      # @return [String]
      def base_value
        if value =~ /^\[?1\d{3}-\d{2}\??\]?$/
          return value.sub(/(\d{2})(\d{2})-(\d{2})/, '\1\2-\1\3')
        end

        value.gsub(/(?<![\d])(\d{1,3})([xu-]{1,3})/i) { "#{Regexp.last_match(1)}#{"0" * Regexp.last_match(2).length}" }.scan(/[\d-]/).join
      end

      # Decoded version of the date with "BCE" or "CE". Strips leading zeroes.
      # @param allowed_precisions [Array<Symbol>] List of allowed precisions for the output.
      #   Defaults to [:day, :month, :year, :decade, :century].
      # @param ignore_unparseable [Boolean] Return nil instead of the original value if it couldn't be parsed
      # @param display_original_value [Boolean] Return the original value if it was not encoded
      # @return [String]
      def decoded_value(allowed_precisions: [:day, :month, :year, :decade, :century], ignore_unparseable: false, display_original_value: true)
        return if ignore_unparseable && !parsed_date?
        return value.strip unless parsed_date?

        if display_original_value
          unless encoding?
            return value.strip unless value =~ /^-?\d+$/ || value =~ /^[\dXxu?-]{4}$/
          end
        end

        if date.is_a?(EDTF::Interval)
          range = [
            Date.format_date(date.min, date.min.precision, allowed_precisions),
            Date.format_date(date.max, date.max.precision, allowed_precisions)
          ].uniq.compact

          return value.strip if range.empty?

          range.join(" - ")
        else
          Date.format_date(date, precision, allowed_precisions) || value.strip
        end
      end

      # Decoded date with "BCE" or "CE" and qualifier markers applied.
      # @see decoded_value
      # @see https://consul.stanford.edu/display/chimera/MODS+display+rules#MODSdisplayrules-3b.%3CoriginInfo%3E
      def qualified_value
        qualified_format = case qualifier
        when "approximate"
          "[ca. %s]"
        when "questionable"
          "[%s?]"
        when "inferred"
          "[%s]"
        else
          "%s"
        end

        format(qualified_format, decoded_value)
      end

      # Range between earliest possible date and latest possible date.
      # @note Some encodings support disjoint sets of ranges, so this method could be less accurate than {#to_a}.
      # @return [Range]
      def as_range
        return unless earliest_date && latest_date

        earliest_date..latest_date
      end

      # Array of all dates that fall into the range of possible dates in the data.
      # @note Some encodings support disjoint sets of ranges, so this method could be more accurate than {#as_range}.
      # @return [Array]
      def to_a
        case date
        when EDTF::Set
          date.to_a
        else
          as_range.to_a
        end
      end

      private

      class << self
        # Returns the date in the format specified by the precision.
        # Supports e.g. retrieving year precision when the actual date is more precise.
        # @param date [Date] The date to format.
        # @param precision [Symbol] The precision to format the date at, e.g. :month
        # @param allowed_precisions [Array<Symbol>] List of allowed precisions for the output.
        #   Options are [:day, :month, :year, :decade, :century].
        # @note allowed_precisions should be ordered by granularity, with most specific first.
        def format_date(date, precision, allowed_precisions)
          precision = allowed_precisions.first unless allowed_precisions.include?(precision)

          case precision
          when :day
            date.strftime("%B %e, %Y")
          when :month
            date.strftime("%B %Y")
          when :year
            year = date.year
            if year < 1
              "#{year.abs + 1} BCE"
            # Any dates before the year 1000 are explicitly marked CE
            elsif year >= 1 && year < 1000
              "#{year} CE"
            else
              year.to_s
            end
          when :decade
            "#{EDTF::Decade.new(date.year).year}s"
          when :century
            if date.year.negative?
              "#{((date.year / 100).abs + 1).ordinalize} century BCE"
            else
              "#{((date.year / 100) + 1).ordinalize} century"
            end
          end
        end
      end

      # Earliest possible date encoded in data, respecting unspecified/imprecise info.
      # @return [Date]
      def earliest_date
        return nil if date.nil?

        case date_range
        when EDTF::Unknown
          nil
        when EDTF::Epoch, EDTF::Interval, EDTF::Season
          date_range.min
        when EDTF::Set
          date_range.to_a.first
        else
          d = date.dup
          d = d.change(month: 1, day: 1) if date.precision == :year
          d = d.change(day: 1) if date.precision == :month
          d = d.change(month: 1) if date.unspecified.unspecified? :month
          d = d.change(day: 1) if date.unspecified.unspecified? :day
          d
        end
      end

      # Latest possible date encoded in data, respecting unspecified/imprecise info.
      # @return [Date]
      def latest_date
        return nil if date.nil?

        case date_range
        when EDTF::Unknown
          nil
        when EDTF::Epoch, EDTF::Interval, EDTF::Season
          date_range.max
        when EDTF::Set
          date_range.to_a.last.change(month: 12, day: 31)
        else
          d = date.dup
          d = d.change(month: 12, day: 31) if date.precision == :year
          d = d.change(day: days_in_month(date.month, date.year)) if date.precision == :month
          d = d.change(month: 12) if date.unspecified.unspecified? :month
          d = d.change(day: days_in_month(date.month, date.year)) if date.unspecified.unspecified? :day
          d
        end
      end

      # Expand placeholders like "19XX" into an object representing the full range.
      # @note This is different from dates with an explicit start/end in the Cocina.
      # @see CocinaDisplay::Dates::DateRange
      # @return [Date]
      def date_range
        @date_range ||= if /u/.match?(value)
          ::Date.edtf(value.tr("u", "x").tr("X", "x")) || date
        else
          date
        end
      end

      # Helper for calculating days in a month, accounting for leap years.
      # @param [Integer] month
      # @param [Integer] year
      # @return [Integer] Number of days in the month
      def days_in_month(month, year)
        if month == 2 && ::Date.gregorian_leap?(year)
          29
        else
          [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month]
        end
      end
    end

    # Strict ISO8601-encoded date parser.
    class Iso8601Format < Date
      def self.parse_date(value)
        ::Date.parse(normalize_to_edtf(value))
      end
    end

    # Less strict W3CDTF-encoded date parser.
    class W3cdtfFormat < Date
      def self.normalize_to_edtf(value)
        super.gsub("-00", "")
      end
    end

    # Strict EDTF parser.
    class EdtfFormat < Date
      attr_reader :date

      def self.normalize_to_edtf(value)
        return "0000" if value.strip == "0"

        case value
        when /^\d{1,3}$/
          value.rjust(4, "0") if /^\d{1,3}$/.match?(value)
        when /^-\d{1,3}$/
          "-#{value.sub(/^-/, "").rjust(4, "0")}"
        else
          value
        end
      end
    end

    # MARC date parser; similar to EDTF but with some MARC-specific encodings.
    class MarcFormat < Date
      def self.normalize_to_edtf(value)
        return nil if value == "9999" || value == "uuuu" || value == "||||"

        super
      end

      private

      def earliest_date
        if value == "1uuu"
          ::Date.parse("1000-01-01")
        else
          super
        end
      end

      def latest_date
        if value == "1uuu"
          ::Date.parse("1999-12-31")
        else
          super
        end
      end
    end

    # Base class for date formats that match using a regex.
    class ExtractorDateFormat < Date
      def self.supports?(value)
        value.match self::REGEX
      end
    end

    # A date format that cannot be parsed or recognized.
    class UnparseableDate < ExtractorDateFormat
      def self.parse_date(value)
        nil
      end
    end

    # Extractor for dates that already match EDTF, they just didn't declare it
    # Matches YYYY-MM-DD, YYYY-MM and YYYY; no further normalization needed
    class UndeclaredEdtfFormat < ExtractorDateFormat
      REGEX = /^(?<year>\d{4})(?:-(?<month>\d{2}))?(?:-(?<day>\d{2}))?$/
    end

    # Extractor for MM/DD/YYYY and MM/DD/YYY-formatted dates
    class MMDDYYYYFormat < ExtractorDateFormat
      REGEX = /(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{3,4})/

      def self.normalize_to_edtf(value)
        matches = value.match(self::REGEX)
        "#{matches[:year].rjust(4, "0")}-#{matches[:month].rjust(2, "0")}-#{matches[:day].rjust(2, "0")}"
      end
    end

    # Extractor for MM/DD/YY-formatted dates
    class MMDDYYFormat < ExtractorDateFormat
      REGEX = /(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{2})/

      def self.normalize_to_edtf(value)
        matches = value.match(self::REGEX)
        year = munge_to_yyyy(matches[:year])
        "#{year}-#{matches[:month].rjust(2, "0")}-#{matches[:day].rjust(2, "0")}"
      end

      # For two-digit year, if it would be in the future, more likely to just
      # be the previous century. 12/1/99 -> 1999
      def self.munge_to_yyyy(year)
        if year.to_i > (::Date.current.year - 2000)
          "19#{year}"
        else
          "20#{year}"
        end
      end
    end

    # Extractor for dates encoded as Roman numerals.
    class RomanNumeralYearFormat < ExtractorDateFormat
      REGEX = /(?<![A-Za-z\.])(?<year>[MCDLXVI\.]+)(?![A-Za-z])/

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        roman_to_int(matches[:year].upcase).to_s
      end

      def self.roman_to_int(value)
        value = value.tr(".", "")
        map = {"M" => 1000, "CM" => 900, "D" => 500, "CD" => 400, "C" => 100, "XC" => 90, "L" => 50, "XL" => 40, "X" => 10, "IX" => 9, "V" => 5, "IV" => 4, "I" => 1}
        result = 0
        map.each do |k, v|
          while value.index(k) == 0
            result += v
            value.slice! k
          end
        end
        result
      end
    end

    # Extractor for centuries encoded as Roman numerals; sometimes centuries
    # are given as e.g. xvith, hence the funny negative look-ahead assertion
    class RomanNumeralCenturyFormat < RomanNumeralYearFormat
      REGEX = /(?<![a-z])(?<century>[xvi]+)(?![a-su-z])/

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        munge_to_yyyy(matches[:century])
      end

      def self.munge_to_yyyy(text)
        value = roman_to_int(text.upcase)
        (value - 1).to_s.rjust(2, "0") + "xx"
      end
    end

    # Extractor for a flavor of century encoding present in Stanford data
    # of unknown origin.
    class MysteryCenturyFormat < ExtractorDateFormat
      REGEX = /(?<century>\d{2})--/
      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        "#{matches[:century]}xx"
      end
    end

    # Extractor for dates given as centuries
    class CenturyFormat < ExtractorDateFormat
      REGEX = /(?<century>\d{2})th C(?:entury)?/i

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        "#{matches[:century].to_i - 1}xx"
      end
    end

    # Extractor for data formatted as YYYY-YYYY or YYY-YYY
    class YearRangeFormat < ExtractorDateFormat
      REGEX = /(?<start>\d{3,4})-(?<end>\d{3,4})/

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        "#{matches[:start].rjust(4, "0")}/#{matches[:end].rjust(4, "0")}"
      end
    end

    # Extractor for data formatted as YYY-
    class DecadeAsYearDashFormat < ExtractorDateFormat
      REGEX = /(?<!\d)(?<year>\d{3})[-_xu?](?!\d)/

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        "#{matches[:year]}x"
      end
    end

    # Extractor for data formatted as YYY0s
    class DecadeStringFormat < ExtractorDateFormat
      REGEX = /(?<!\d)(?<year>\d{3})0s(?!\d)/

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        "#{matches[:year]}x"
      end
    end

    # Extractor that tries hard to pick any BC year present in the data
    class EmbeddedBCYearFormat < ExtractorDateFormat
      REGEX = /(?<year>\d{3,4})\s?B\.?C\.?/i

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        "-#{(matches[:year].to_i - 1).to_s.rjust(4, "0")}"
      end
    end

    # Extractor that tries hard to pick any year present in the data
    class EmbeddedYearFormat < ExtractorDateFormat
      REGEX = /(?<!\d)(?<year>\d{4})(?!\d)/

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        matches[:year].rjust(4, "0")
      end
    end

    # Extractor that tries hard to pick any 3-digit year present in the data
    class EmbeddedThreeDigitYearFormat < ExtractorDateFormat
      REGEX = /(?<!\d)(?<year>\d{3})(?!\d)(?!\d)/

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        matches[:year].rjust(4, "0")
      end
    end

    # Extractor that tries hard to pick any 1- or 2-digit year present in the data
    class OneOrTwoDigitYearFormat < ExtractorDateFormat
      REGEX = /^(?<year>\d{1,2})$/

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        matches[:year].rjust(4, "0")
      end
    end

    # Full-text extractor that tries hard to pick any bracketed year present in the data
    class EmbeddedYearWithBracketsFormat < ExtractorDateFormat
      # [YYY]Y Y[YYY] [YY]YY Y[YY]Y YY[YY] YYY[Y] YY[Y]Y Y[Y]YY [Y]YYY
      REGEX = /(?<year>[\d\[\]]{6})(?!\d)/

      def self.normalize_to_edtf(text)
        matches = text.match(REGEX)
        matches[:year].delete("[").delete("]")
      end
    end
  end
end
