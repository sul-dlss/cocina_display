module CocinaDisplay
  module Subjects
    # A descriptive value that can be part of a Subject.
    class SubjectValue
      attr_reader :cocina

      # The type of the subject value, like "person", "title", or "time".
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#subject-part-types-for-structured-value
      attr_accessor :type

      # Create a SubjectValue from Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the subject.
      # @return [SubjectValue]
      def self.from_cocina(cocina)
        SUBJECT_VALUE_TYPES.fetch(cocina["type"], SubjectValue).new(cocina)
      end

      # All subject value types that should not be further destructured.
      # @return [Array<String>]
      def self.atomic_types
        SUBJECT_VALUE_TYPES.keys - ["place"]
      end

      # Initialize a SubjectValue object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the subject value.
      def initialize(cocina)
        @cocina = cocina
        @type = cocina["type"]
      end

      # The display string for the subject value.
      # Subclasses should override this method to provide specific formatting.
      # @return [String]
      def to_s
        cocina["value"]
      end
    end

    # A subject value representing a named entity.
    class NameSubjectValue < SubjectValue
      attr_reader :name

      # Initialize a NameSubjectValue object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the subject.
      def initialize(cocina)
        super
        @name = Contributors::Name.new(cocina)
      end

      # Use the contributor name formatting rules for display.
      # @return [String] The formatted name string, including life dates
      # @see CocinaDisplay::Contributor::Name#to_s
      def to_s
        name.to_s(with_date: true)
      end
    end

    # A subject value representing an entity with a title.
    class TitleSubjectValue < SubjectValue
      attr_reader :title

      # Initialize a TitleSubjectValue object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the subject.
      def initialize(cocina)
        super
        @title = Title.new(cocina)
      end

      # Construct a title string to use for display.
      # @see CocinaDisplay::Title#to_s
      # @return [String, nil]
      def to_s
        title.to_s
      end
    end

    # A subject value representing a date and/or time.
    class TemporalSubjectValue < SubjectValue
      attr_reader :date

      def initialize(cocina)
        super
        @date = Dates::Date.from_cocina(cocina)
      end

      # @return [String] The formatted date/time string for display
      def to_s
        date.qualified_value
      end
    end

    # A subject value representing a named place.
    class PlaceSubjectValue < SubjectValue
      # A URI identifying the place, if available.
      # @return [String, nil]
      def uri
        cocina["uri"]
      end

      # True if the place has a geonames.org URI.
      # @return [Boolean]
      def geonames?
        uri&.include?("sws.geonames.org")
      end

      # Unique identifier for the place in geonames.org.
      # @return [String, nil]
      def geonames_id
        uri&.split("/")&.last if geonames?
      end
    end

    # A subject value containing geographic coordinates, like a point or box.
    class CoordinatesSubjectValue < SubjectValue
      attr_reader :coordinates

      def initialize(cocina)
        super
        @coordinates = Geospatial::Coordinates.from_cocina(cocina)
      end

      # The normalized DMS string for the coordinates.
      # Falls back to the raw value if parsing fails.
      # @return [String, nil]
      def to_s
        coordinates&.to_s || super
      end
    end
  end
end

# Map Cocina subject types to specific SubjectValue classes for rendering.
# @see SubjectValue#type
SUBJECT_VALUE_TYPES = {
  "person" => CocinaDisplay::Subjects::NameSubjectValue,
  "family" => CocinaDisplay::Subjects::NameSubjectValue,
  "organization" => CocinaDisplay::Subjects::NameSubjectValue,
  "conference" => CocinaDisplay::Subjects::NameSubjectValue,
  "event" => CocinaDisplay::Subjects::NameSubjectValue,
  "name" => CocinaDisplay::Subjects::NameSubjectValue,
  "title" => CocinaDisplay::Subjects::TitleSubjectValue,
  "time" => CocinaDisplay::Subjects::TemporalSubjectValue,
  "area" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "city" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "city section" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "continent" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "country" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "county" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "coverage" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "extraterrestrial area" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "island" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "place" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "region" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "state" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "territory" => CocinaDisplay::Subjects::PlaceSubjectValue,
  "point coordinates" => CocinaDisplay::Subjects::CoordinatesSubjectValue,
  "map coordinates" => CocinaDisplay::Subjects::CoordinatesSubjectValue,
  "bounding box coordinates" => CocinaDisplay::Subjects::CoordinatesSubjectValue
}.freeze
