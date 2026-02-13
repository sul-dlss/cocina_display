# frozen_string_literal: true

module CocinaDisplay
  module Concerns
    # Methods for extracting geospatial metadata, such as coordinates.
    module Geospatial
      # All coordinate data as DMS format strings.
      # @return [Array<String>]
      # @example ["34°03′08″N 118°14′37″W"]
      def coordinates
        coordinate_subject_values.map(&:to_s).compact.uniq
      end

      # All valid coordinate data formatted for indexing into a Solr RPT field.
      # @note This type of field accommodates both points and bounding boxes.
      # @note In WKT, points have longitude first, unlike {coordinates_as_point}.
      # @see https://solr.apache.org/guide/solr/latest/query-guide/spatial-search.html#rpt
      # @return [Array<String>]
      # @example ["POINT(-118.2437 34.0522)", "POLYGON((-118.2437 34.0522, -118.2437 34.1996, -117.9522 34.1996, -117.9522 34.0522, -118.2437 34.0522))"]
      def coordinates_as_wkt
        coordinate_objects.map(&:as_wkt).uniq
      end

      # All valid coordinate data formatted for indexing into a Solr BBoxField.
      # @note Points are not included since they can't be represented as a box.
      # @see https://solr.apache.org/guide/solr/latest/query-guide/spatial-search.html#bboxfield
      # @return [Array<String>]
      # @example ["ENVELOPE(-118.2437, -117.9522, 34.1996, 34.0522)"]
      def coordinates_as_envelope
        coordinate_objects.map(&:as_envelope).compact.uniq
      end

      # All valid coordinate data formatted for indexing into a Solr LatLon field.
      # @note Bounding boxes are automatically converted to their center point.
      # @see https://solr.apache.org/guide/solr/latest/query-guide/spatial-search.html#indexing-points
      # @return [Array<String>]
      # @example ["34.0522,-118.2437"]
      def coordinates_as_point
        coordinate_objects.map(&:as_point).uniq
      end

      # Identifiers assigned by geonames.org for places related to the object.
      # @return [Array<String>]
      # @example ["6252001", "5368361"]
      def geonames_ids
        place_subject_values.map { |s| s.geonames_id }.compact.uniq
      end

      private

      # {Subject} objects with types that could contain coordinate information.
      # @return [Array<Subject>]
      def coordinate_subjects
        all_subjects.filter { |subject| subject.type&.include? "coordinates" }
      end

      # Parsed coordinate values from the coordinate subject values.
      # @return [Array<Geospatial::Coordinates>]
      def coordinate_objects
        coordinate_subject_values.filter_map(&:coordinates)
      end

      # All subject values that could contain parsed coordinates.
      # @return [Array<Subjects::CoordinatesSubjectValue>]
      def coordinate_subject_values
        subject_values.filter { |s| s.is_a? CocinaDisplay::Subjects::CoordinatesSubjectValue }
      end
    end
  end
end
