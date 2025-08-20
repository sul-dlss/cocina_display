require "geo/coord"

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
            lat = structured_values.find { |v| v["type"] == "latitude" }&.dig("value")
            lng = structured_values.find { |v| v["type"] == "longitude" }&.dig("value")
            Point.from_coords(lat: lat, lng: lng)
          elsif structured_values.size == 4
            north = structured_values.find { |v| v["type"] == "north" }&.dig("value")
            south = structured_values.find { |v| v["type"] == "south" }&.dig("value")
            east = structured_values.find { |v| v["type"] == "east" }&.dig("value")
            west = structured_values.find { |v| v["type"] == "west" }&.dig("value")
            BoundingBox.from_coords(west: west, east: east, north: north, south: south)
          end
        end

        # Convert a single string value into a Coordinates object.
        # Chooses a parsing strategy based on the string format.
        # @param [String] value
        # @return [Coordinates, nil]
        def parse(value)
          # Remove all whitespace for easier matching/parsing
          match_str = value.gsub(/[\s]+/, "")

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
      # @example "POINT(34.0522 -118.2437)"
      # @return [String]
      def as_wkt
        "POINT(%.6f %.6f)" % [point.lat, point.lng]
      end

      # Format using the CQL ENVELOPE representation.
      # @note This is impossible for a single point; we always return nil.
      # @return [nil]
      def as_envelope
        nil
      end

      # Format as a comma-separated latitude,longitude pair.
      # @note Limits decimals to 6 places.
      # @example "34.0522,-118.2437"
      # @return [String]
      def as_point
        "%.6f,%.6f" % [point.lat, point.lng]
      end
    end

    # A bounding box defined by two corner points.
    class BoundingBox < Coordinates
      attr_reader :min_point, :max_point

      # Construct a BoundingBox from west, east, north, and south string values.
      # @param [String] west western longitude
      # @param [String] east eastern longitude
      # @param [String] north northern latitude
      # @param [String] south southern latitude
      # @return [BoundingBox, nil] nil if parsing fails
      def self.from_coords(west:, east:, north:, south:)
        min_point = Geo::Coord.parse("#{south}, #{west}")
        max_point = Geo::Coord.parse("#{north}, #{east}")

        # Must be parsable
        return unless min_point && max_point

        # Ensure min_point is southwest and max_point is northeast
        return if min_point.lat > max_point.lat || min_point.lng > max_point.lng

        new(min_point: min_point, max_point: max_point)
      end

      # Construct a BoundingBox from two Geo::Coord points.
      # @param [Geo::Coord] min_point
      # @param [Geo::Coord] max_point
      def initialize(min_point:, max_point:)
        @min_point = min_point
        @max_point = max_point
      end

      # Format for display in DMS format, adapted from ISO 6709 standard.
      # @note This format adapts the "Annex D" human representation style.
      # @see https://en.wikipedia.org/wiki/ISO_6709
      # @return [String]
      # @example "118°14′37″W -- 117°56′55″W / 34°03′08″N -- 34°11′59″N"
      def to_s
        min_lat, min_lng = format_point(min_point)
        max_lat, max_lng = format_point(max_point)
        "#{min_lng} -- #{max_lng} / #{max_lat} -- #{min_lat}"
      end

      # Format using the Well-Known Text (WKT) representation.
      # @note Limits decimals to 6 places.
      # @see https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry
      # @return [String]
      def as_wkt
        "POLYGON((%.6f %.6f, %.6f %.6f, %.6f %.6f, %.6f %.6f, %.6f %.6f))" % [
          min_point.lng, min_point.lat,
          max_point.lng, min_point.lat,
          max_point.lng, max_point.lat,
          min_point.lng, max_point.lat,
          min_point.lng, min_point.lat
        ]
      end

      # Format using the CQL ENVELOPE representation.
      # @note Limits decimals to 6 places.
      # @example "ENVELOPE(-118.243700, -117.952200, 34.199600, 34.052200)"
      # @return [String]
      def as_envelope
        "ENVELOPE(%.6f, %.6f, %.6f, %.6f)" % [
          min_point.lng, max_point.lng, max_point.lat, min_point.lat
        ]
      end

      # The box center point as a comma-separated latitude,longitude pair.
      # @note Limits decimals to 6 places.
      # @example "34.0522,-118.2437"
      # @return [String]
      def as_point
        azimuth = min_point.azimuth(max_point)
        distance = min_point.distance(max_point)
        center = min_point.endpoint(distance / 2, azimuth)
        "%.6f,%.6f" % [center.lat, center.lng]
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
    end

    # Mixin that adds normalization for decimal degree coordinates.
    module DecimalParser
      def self.included(base)
        base.extend(Helpers)
      end

      module Helpers
        # Convert hemispheres to plus/minus signs for parsing.
        # @param [String] coord_str
        # @return [String]
        def normalize_coord(coord_str)
          coord_str.tr("EN", "+").tr("WS", "-")
        end
      end
    end

    # Mixin that adds normalization for DMS coordinates.
    module DMSParser
      POINT_PATTERN = /(?<hem>[NESW])(?<deg>\d{1,3})[°⁰º]?(?:(?<min>\d{1,2})[ʹ′']?)?(?:(?<sec>\d{1,2})[ʺ"″]?)?/

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

        min_lng = normalize_coord(matches[:min_lng])
        max_lng = normalize_coord(matches[:max_lng])
        min_lat = normalize_coord(matches[:min_lat])
        max_lat = normalize_coord(matches[:max_lat])

        BoundingBox.from_coords(west: min_lng, east: max_lng, north: max_lat, south: min_lat)
      end
    end

    # Parse for decimal degree points, like "41.891797, 12.486419".
    class DecimalPointParser < PointParser
      include DecimalParser
      PATTERN = /(?<lat>[0-9.EW\+\-]+),(?<lng>[0-9.NS\+\-]+)/
    end

    # Parser for DMS-format points, like "N34°03′08″ W118°14′37″".
    class DMSPointParser < PointParser
      include DMSParser
      PATTERN = /(?<lat>[^EW]+)(?<lng>[^NS]+)/
    end

    # DMS-format bounding boxes with varying punctuation, delimited by -- and /.
    # @note This data can come from the MARC 255$c field.
    # @see https://www.oclc.org/bibformats/en/2xx/255.html#subfieldc
    class DMSBoundingBoxParser < BoundingBoxParser
      include DMSParser
      PATTERN = /(?<min_lng>.+?)-+(?<max_lng>.+)\/(?<max_lat>.+?)-+(?<min_lat>.+)/
    end

    # Format that pairs hemispheres with decimal degrees.
    # @example W 126.04--W 052.03/N 050.37--N 006.8
    class DecimalBoundingBoxParser < BoundingBoxParser
      include DecimalParser
      PATTERN = /(?<min_lng>[0-9.EW]+?)-+(?<max_lng>[0-9.EW]+)\/(?<max_lat>[0-9.NS]+?)-+(?<min_lat>[0-9.NS]+)/
    end

    # DMS-format data that appears to come from MARC 034 subfields.
    # @see https://www.oclc.org/bibformats/en/0xx/034.html
    # @example $dW0963700$eW0900700$fN0433000$gN040220
    class MarcDMSBoundingBoxParser < DMSBoundingBoxParser
      PATTERN = /\$d(?<min_lng>[WENS].+)\$e(?<max_lng>[WENS].+)\$f(?<max_lat>[WENS].+)\$g(?<min_lat>[WENS].+)/
    end

    # Decimal degree format data that appears to come from MARC 034 subfields.
    # @see https://www.oclc.org/bibformats/en/0xx/034.html
    # @example $d-112.0785250$e-111.6012719$f037.6516503$g036.8583209
    class MarcDecimalBoundingBoxParser < DecimalBoundingBoxParser
      PATTERN = /\$d(?<min_lng>[0-9.-]+)\$e(?<max_lng>[0-9.-]+)\$f(?<max_lat>[0-9.-]+)\$g(?<min_lat>[0-9.-]+)/
    end
  end
end
