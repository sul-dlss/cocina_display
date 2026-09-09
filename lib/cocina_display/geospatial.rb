# frozen_string_literal: true

module CocinaDisplay
  module Geospatial
    # Abstract class representing multiple geospatial coordinates, like a point or box.
    class Coordinates
      class << self
        # Convert Cocina structured data into a Coordinates object.
        # Chooses a parsing strategy based on the cocina structure.
        # @param [Hash] cocina
        # @return [Coordinates, nil]
        def from_cocina(cocina)
          return from_structured_values(cocina["structuredValue"]) if Array(cocina["structuredValue"]).any?
          parse(cocina["value"]) if cocina["value"].present?
        end

        # Convert structured values into the appropriate Coordinates object.
        # Handles points and bounding boxes.
        # @param [Array<Hash>] structured_values
        # @return [Coordinates, nil]
        def from_structured_values(structured_values)
          if structured_values.size == 2
            Point.from_coords(
              lat: structured_value(structured_values, "latitude"),
              lng: structured_value(structured_values, "longitude")
            )
          elsif structured_values.size == 4
            BoundingBox.from_coords(
              west: structured_value(structured_values, "west"),
              east: structured_value(structured_values, "east"),
              north: structured_value(structured_values, "north"),
              south: structured_value(structured_values, "south")
            )
          end
        end

        # Convert a single string value into a Coordinates object.
        # Chooses a parsing strategy based on the string format.
        # @param [String] value
        # @return [Coordinates, nil]
        def parse(value)
          # Remove all whitespace for easier matching/parsing
          match_str = value.gsub(/\s+/, "")

          # Try each parser in order until one matches; bail out if none do
          parser_class = [
            MarcDecimalBoundingBoxParser,
            MarcDMSBoundingBoxParser,
            DecimalBoundingBoxParser,
            DMSBoundingBoxParser,
            DecimalPointParser,
            DMSPointParser
          ].find { |parser| parser.supports?(match_str) }
          return unless parser_class

          # Use the matching parser to parse the string
          parser_class.parse(match_str)
        end

        private

        # Find a single coordinate value of the given type in structured data.
        # @param [Array<Hash>] structured_values
        # @param [String] type like "west" or "latitude"
        # @return [String, nil]
        def structured_value(structured_values, type)
          value = structured_values.find { |v| v["type"] == type }&.dig("value")
          normalize_value(value) if value.present?
        end

        # Standardize a single coordinate value so that Geo::Coord can parse it.
        # Chooses a normalizer based on the string format, since structured values
        # can be decimal degrees or DMS, including the packed MARC 034 form.
        # @param [String] value
        # @return [String, nil] nil if the format isn't recognized
        # @example "W1210000" becomes "121°0′0″W"
        def normalize_value(value)
          # Remove all whitespace for easier matching/parsing
          match_str = value.gsub(/\s+/, "")

          # Try each normalizer in order until one matches; bail out if none do
          normalizer_class = [
            DMSCoordinateNormalizer,
            DecimalCoordinateNormalizer
          ].find { |normalizer| normalizer.supports?(match_str) }

          normalizer_class&.normalize_coord(match_str)
        end
      end

      protected

      # Format a point for display in DMS, adapted from ISO 6709 standard.
      # @note This format adapts the "Annex D" human representation style.
      # @see https://en.wikipedia.org/wiki/ISO_6709
      # @param [Geo::Coord] point
      # @return [Array<String>] [latitude, longitude]
      # @example ["34°03′08″N", "118°14′37″W"]
      def format_point(point)
        # Geo::Coord#strfcoord performs rounding & carrying for us, but
        # it can't natively zero-pad minutes and seconds to two digits
        [
          normalize_coord(point.strfcoord("%latd %latm %lats %lath")),
          normalize_coord(point.strfcoord("%lngd %lngm %lngs %lngh"))
        ]
      end

      # Reformat a coordinate string to ensure two-digit minutes and seconds.
      # Expects space-separated output of Geo::Coord#strfcoord.
      # @example "121 4 6 W" becomes "121°04′06″W"
      # @param [String] coord_str
      # @return [String]
      def normalize_coord(coord_str)
        d, m, s, h = coord_str.split(" ")
        "%d°%02d′%02d″%s" % [d.to_i, m.to_i, s.to_i, h]
      end
    end

    # A single geospatial point with latitude and longitude.
    class Point < Coordinates
      attr_reader :point

      # Construct a Point from latitude and longitude string values.
      # @param [String] lat latitude
      # @param [String] lng longitude
      # @return [Point, nil] nil if parsing fails
      def self.from_coords(lat:, lng:)
        point = Geo::Coord.parse("#{lat}, #{lng}")
        return unless point

        new(point)
      end

      # Construct a Point from a single Geo::Coord point.
      # @param [Geo::Coord] point
      def initialize(point)
        @point = point
      end

      # Format for display in DMS format, adapted from ISO 6709 standard.
      # @note This format adapts the "Annex D" human representation style.
      # @see https://en.wikipedia.org/wiki/ISO_6709
      # @return [String]
      # @example "34°03′08″N 118°14′37″W"
      def to_s
        format_point(point).join(" ")
      end

      # Format using the Well-Known Text (WKT) representation.
      # @note Limits decimals to 6 places.
      # @see https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry
      # @example "POINT(-118.2437 34.0522)"
      # @return [String]
      def as_wkt
        "POINT(%.6f %.6f)" % [point.lng, point.lat]
      end

      # Format using the CQL ENVELOPE representation.
      # @note This is impossible for a single point; we always return nil.
      # @return [nil]
      def as_envelope
        nil
      end

      # Format as a bounding box.
      # @note This is impossible for a single point; we always return nil.
      # @return [nil]
      def as_bbox
        nil
      end

      # Format as a space-separated x y (longitude latitude) pair.
      # @note Limits decimals to 6 places.
      # @example "-118.2437 34.0522"
      # @return [String]
      def as_point
        "%.6f %.6f" % [point.lng, point.lat]
      end
    end

    # A bounding box defined by its southwest and northeast corner points.
    # The box can wrap east-west across the antimeridian, in which case its west
    # edge is numerically east of its east edge. Both Solr's rectangle syntax and
    # GeoJSON spell a crossing box that way, as do MARC 034 $d/$e, which are the
    # westernmost and easternmost longitudes rather than the minimum and maximum.
    # @see https://datatracker.ietf.org/doc/html/rfc7946#section-5.2
    class BoundingBox < Coordinates
      attr_reader :southwest, :northeast

      # Construct a BoundingBox from west, east, north, and south string values.
      # West and east are used as given, so a box that crosses the antimeridian
      # is preserved instead of rejected.
      # @param [String] west western longitude
      # @param [String] east eastern longitude
      # @param [String] north northern latitude
      # @param [String] south southern latitude
      # @return [BoundingBox, nil] nil if parsing fails
      def self.from_coords(west:, east:, north:, south:)
        southwest = Geo::Coord.parse("#{south}, #{west}")
        northeast = Geo::Coord.parse("#{north}, #{east}")

        # Must be parsable
        return unless southwest && northeast

        # A box can wrap east-west, but never north-south
        return if southwest.lat > northeast.lat

        new(southwest: southwest, northeast: northeast)
      end

      # Construct a BoundingBox from two corner Geo::Coord points.
      # @param [Geo::Coord] southwest
      # @param [Geo::Coord] northeast
      def initialize(southwest:, northeast:)
        @southwest = southwest
        @northeast = northeast
      end

      # The westernmost longitude of the box.
      # @return [BigDecimal]
      def west
        southwest.lng
      end

      # The easternmost longitude of the box.
      # @return [BigDecimal]
      def east
        northeast.lng
      end

      # The northernmost latitude of the box.
      # @return [BigDecimal]
      def north
        northeast.lat
      end

      # The southernmost latitude of the box.
      # @return [BigDecimal]
      def south
        southwest.lat
      end

      # True if the box wraps east-west across the antimeridian.
      # @return [Boolean]
      def crosses_antimeridian?
        west > east
      end

      # Format for display in DMS format, adapted from ISO 6709 standard.
      # @note This format adapts the "Annex D" human representation style.
      # @see https://en.wikipedia.org/wiki/ISO_6709
      # @return [String]
      # @example "118°14′37″W -- 117°56′55″W / 34°03′08″N -- 34°11′59″N"
      def to_s
        south_str, west_str = format_point(southwest)
        north_str, east_str = format_point(northeast)
        "#{west_str} -- #{east_str} / #{north_str} -- #{south_str}"
      end

      # Format using the Well-Known Text (WKT) representation.
      # @note Limits decimals to 6 places.
      # @note A box crossing the antimeridian is split into two polygons at the
      #   date line, so that every longitude stays within bounds.
      # @see https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry
      # @see https://datatracker.ietf.org/doc/html/rfc7946#section-3.1.9
      # @return [String]
      def as_wkt
        return "POLYGON(#{ring(west, east)})" unless crosses_antimeridian?

        "MULTIPOLYGON((#{ring(west, 180)}), (#{ring(-180, east)}))"
      end

      # Format using the CQL ENVELOPE representation.
      # @note Limits decimals to 6 places.
      # @note West is greater than east for a box crossing the antimeridian.
      # @example "ENVELOPE(-118.2437, -117.9522, 34.1996, 34.0522)"
      # @return [String]
      def as_envelope
        "ENVELOPE(%.6f, %.6f, %.6f, %.6f)" % [west, east, north, south]
      end

      # The box center point as a space-separated x y (longitude latitude) pair.
      # @note Limits decimals to 6 places.
      # @example "-118.2437 34.0522"
      # @return [String]
      def as_point
        center_lng = (west + unwrapped_east) / 2
        center_lng -= 360 if center_lng > 180
        "%.6f %.6f" % [center_lng, (south + north) / 2]
      end

      # Format the bounding box as an array of two coordinate pairs [[S, W], [N, E]].
      # @note Limits decimals to 6 places.
      # @note For a box crossing the antimeridian, east is carried past 180 so that
      #   the pair still reads southwest to northeast.
      # @return [Array<Array<Float>>]
      # @example [[34.0522, -118.2437], [34.1996, -117.9522]]
      def as_bbox
        [[south, west], [north, unwrapped_east]]
      end

      private

      # The east edge as a continuous longitude, carried past 180 if the box
      # crosses the antimeridian.
      # @return [BigDecimal]
      def unwrapped_east
        crosses_antimeridian? ? east + 360 : east
      end

      # A closed WKT linear ring for the box, spanning the given longitudes.
      # @note Limits decimals to 6 places.
      # @param [Numeric] west_lng
      # @param [Numeric] east_lng
      # @return [String]
      def ring(west_lng, east_lng)
        "(%.6f %.6f, %.6f %.6f, %.6f %.6f, %.6f %.6f, %.6f %.6f)" % [
          west_lng, south,
          east_lng, south,
          east_lng, north,
          west_lng, north,
          west_lng, south
        ]
      end
    end

    # Base class for parsers that convert strings into Coordinates objects.
    # Subclasses must define at least the PATTERN constant and self.parse method.
    class CoordinatesParser
      PATTERN = nil

      # If true, use this parser for the given input string.
      # @param [String] input_str
      # @return [Boolean]
      def self.supports?(input_str)
        input_str.match?(self::PATTERN)
      end

      # Move a trailing hemisphere letter to the front, since that is where the
      # decimal normalizer expects it.
      # @example "121.5W" becomes "W121.5"
      # @param [String] value
      # @return [String]
      def self.hemisphere_first(value)
        value.sub(/\A(.+?)([NESW])\z/, '\2\1')
      end
    end

    # Mixin that adds normalization for decimal degree coordinates.
    module DecimalParser
      def self.included(base)
        base.extend(Helpers)
      end

      module Helpers
        # Convert hemispheres to plus/minus signs for parsing.
        # @note The hemisphere can either lead or trail the degrees.
        # @param [String] coord_str
        # @return [String]
        def normalize_coord(coord_str)
          hemisphere_first(coord_str).tr("EN", "+").tr("WS", "-")
        end
      end
    end

    # Mixin that adds normalization for DMS coordinates.
    module DMSParser
      # The degrees, minutes, and seconds of a coordinate, without a hemisphere.
      DMS_PATTERN = /(?<deg>\d{1,3})[°⁰º]?(?:(?<min>\d{1,2})[ʹ′']?)?(?:(?<sec>\d{1,2})[ʺ"″]?)?/

      # A single coordinate, with the hemisphere either leading or trailing the
      # degrees. A hemisphere is required, so that a bare number is not read as
      # a coordinate. Both spellings are common in MARC 034 and 255$c, and the
      # trailing form is what {Coordinates#format_point} itself emits.
      # @note A trailing hemisphere cannot be followed by digits, otherwise a
      #   MARC 034 $b scale like "$b3100000W120°00′00″" would read the scale as
      #   the degrees and steal the hemisphere from the coordinate after it.
      POINT_PATTERN = /(?:(?<hem>[NESW])#{DMS_PATTERN}|#{DMS_PATTERN}(?<hem>[NESW])(?!\d))/

      def self.included(base)
        base.const_set(:POINT_PATTERN, POINT_PATTERN)
        base.extend(Helpers)
      end

      module Helpers
        # Standardize coordinate format so Geo::Coord can parse it.
        # @param [String] coord_str
        # @return [String]
        def normalize_coord(coord_str)
          matches = coord_str.match(self::POINT_PATTERN)
          return unless matches

          hem = matches[:hem]
          deg = matches[:deg].to_i
          min = matches[:min].to_i
          sec = matches[:sec].to_i

          "#{deg}°#{min}′#{sec}″#{hem}"
        end
      end
    end

    # Base class for point parsers.
    class PointParser < CoordinatesParser
      # Parse the input string into a Point, or nil if parsing fails.
      # @param [String] input_str
      # @return [Point, nil]
      def self.parse(input_str)
        matches = input_str.match(self::PATTERN)
        return unless matches

        lat = normalize_coord(matches[:lat])
        lng = normalize_coord(matches[:lng])

        Point.from_coords(lat: lat, lng: lng)
      end
    end

    # Base class for bounding box parsers.
    class BoundingBoxParser < CoordinatesParser
      # Parse the input string into a BoundingBox, or nil if parsing fails.
      # @param [String] input_str
      # @return [BoundingBox, nil]
      def self.parse(input_str)
        matches = input_str.match(self::PATTERN)
        return unless matches

        west = normalize_coord(matches[:west])
        east = normalize_coord(matches[:east])
        south = normalize_coord(matches[:south])
        north = normalize_coord(matches[:north])

        BoundingBox.from_coords(west: west, east: east, north: north, south: south)
      end
    end

    # Base class for normalizers that standardize a single coordinate value, as
    # found in Cocina structured values, so that Geo::Coord can parse it.
    # Subclasses define a PATTERN and mix in a parser module for normalize_coord.
    class CoordinateNormalizer < CoordinatesParser
    end

    # Normalizes DMS values, including the packed form used in MARC 034 subfields.
    # @example W1210000
    # @example 121°14′48″W
    class DMSCoordinateNormalizer < CoordinateNormalizer
      include DMSParser

      # Either DMS punctuation, or a hemisphere paired with packed digits.
      PATTERN = /[°⁰º′ʹ'″ʺ"]|\A[NESW]\d{4,}\z|\A\d{4,}[NESW]\z/
    end

    # Normalizes decimal degree values, either signed or paired with a hemisphere.
    # @note Degrees are limited to 3 digits so that packed DMS isn't read as decimal.
    # @example -121.24658
    # @example W126.04
    class DecimalCoordinateNormalizer < CoordinateNormalizer
      include DecimalParser

      PATTERN = /\A[NESW+-]?\d{1,3}(?:\.\d+)?[NESW]?\z/
    end

    # Parse for decimal degree points, like "41.891797, 12.486419".
    class DecimalPointParser < PointParser
      include DecimalParser

      PATTERN = /(?<lat>[0-9.EW+-]+),(?<lng>[0-9.NS+-]+)/
    end

    # Parser for DMS-format points, like "N34°03′08″ W118°14′37″".
    # @note The hemisphere can either lead or trail the degrees in each half.
    # @example 34°03′08″N 118°14′37″W
    class DMSPointParser < PointParser
      include DMSParser

      PATTERN = /(?<lat>[NS][^NS]+|[^NS]+[NS])(?<lng>[EW][^EW]+|[^EW]+[EW])/
    end

    # DMS-format bounding boxes with varying punctuation, delimited by -- and /.
    # @note This data can come from the MARC 255$c field.
    # @see https://www.oclc.org/bibformats/en/2xx/255.html#subfieldc
    class DMSBoundingBoxParser < BoundingBoxParser
      include DMSParser

      PATTERN = /(?<west>.+?)-+(?<east>.+)\/(?<north>.+?)-+(?<south>.+)/
    end

    # Format that pairs hemispheres with decimal degrees.
    # @example W 126.04--W 052.03/N 050.37--N 006.8
    class DecimalBoundingBoxParser < BoundingBoxParser
      include DecimalParser

      PATTERN = /(?<west>[0-9.EW]+?)-+(?<east>[0-9.EW]+)\/(?<north>[0-9.NS]+?)-+(?<south>[0-9.NS]+)/
    end

    # DMS-format data that appears to come from MARC 034 subfields.
    # @see https://www.oclc.org/bibformats/en/0xx/034.html
    # @example $dW0963700$eW0900700$fN0433000$gN040220
    class MarcDMSBoundingBoxParser < DMSBoundingBoxParser
      PATTERN = /\$d(?<west>[WENS].+)\$e(?<east>[WENS].+)\$f(?<north>[WENS].+)\$g(?<south>[WENS].+)/
    end

    # Decimal degree format data that appears to come from MARC 034 subfields.
    # @see https://www.oclc.org/bibformats/en/0xx/034.html
    # @example $d-112.0785250$e-111.6012719$f037.6516503$g036.8583209
    class MarcDecimalBoundingBoxParser < DecimalBoundingBoxParser
      PATTERN = /\$d(?<west>[0-9.-]+)\$e(?<east>[0-9.-]+)\$f(?<north>[0-9.-]+)\$g(?<south>[0-9.-]+)/
    end
  end
end
