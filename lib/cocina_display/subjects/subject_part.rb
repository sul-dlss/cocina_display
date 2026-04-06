module CocinaDisplay
  module Subjects
    # A descriptive value that can be part of a structured Subject.
    class SubjectPart
      attr_reader :cocina

      # The type of the subject part, like "person", "title", or "time".
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#subject-part-types-for-structured-value
      attr_accessor :type

      # Create SubjectParts from Cocina structured data.
      # Pre-coordinated string values will be split into multiple SubjectParts.
      # @param cocina [Hash] The Cocina structured data for the subject.
      # @param type [String, nil] The type, coming from the parent Subject.
      # @return [Array<SubjectPart>]
      def self.from_cocina(cocina, type:)
        split_pre_coordinated_values(cocina, type: type).map do |value|
          SUBJECT_PART_TYPES.fetch(type, SubjectPart).new(value).tap do |obj|
            obj.type ||= type
          end
        end
      end

      # Split a pre-coordinated subject value joined with "--" into multiple values.
      # Ignores the "--" string for coordinate subject types, which use it differently.
      # @param cocina [Hash] The Cocina structured data for the subject.
      # @return [Array<Hash>] An array of Cocina hashes, one for each split value
      def self.split_pre_coordinated_values(cocina, type:)
        if cocina["value"].is_a?(String) && cocina["value"].include?("--") && !type&.include?("coordinates")
          cocina["value"].split("--").map { |v| cocina.merge("value" => v.strip) }
        else
          [cocina]
        end
      end

      # All subject part types that should not be further destructured.
      # @return [Array<String>]
      def self.atomic_types
        SUBJECT_PART_TYPES.keys - ["place"]
      end

      # Initialize a SubjectPart object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the subject part.
      def initialize(cocina)
        @cocina = cocina
        @type = cocina["type"]
      end

      # The display string for the subject part.
      # Subclasses should override this method to provide specific formatting.
      # @return [String]
      def to_s
        cocina["value"]
      end
    end

    # A subject part representing a named entity.
    class NameSubjectPart < SubjectPart
      attr_reader :name

      # Initialize a NameSubjectPart object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the subject part.
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

    # A subject part representing an entity with a title.
    class TitleSubjectPart < SubjectPart
      attr_reader :title

      # Initialize a TitleSubjectPart object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the subject part.
      def initialize(cocina)
        super
        @title = Titles::Title.new(cocina)
      end

      # Construct a title string to use for display.
      # @see CocinaDisplay::Title#to_s
      # @return [String, nil]
      def to_s
        title.to_s
      end
    end

    # A subject part representing a date and/or time.
    class TemporalSubjectPart < SubjectPart
      attr_reader :date

      def initialize(cocina)
        super
        @date = Dates::Date.from_cocina(cocina)
      end

      # @return [String] The formatted date/time string for display
      def to_s
        date.to_s
      end
    end

    # A subject part representing a named place.
    class PlaceSubjectPart < SubjectPart
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

    # A subject part containing geographic coordinates, like a point or box.
    class CoordinatesSubjectPart < SubjectPart
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

# Map Cocina subject part types to specific SubjectPart classes for rendering.
# @see SubjectPart#type
SUBJECT_PART_TYPES = {
  "person" => CocinaDisplay::Subjects::NameSubjectPart,
  "family" => CocinaDisplay::Subjects::NameSubjectPart,
  "organization" => CocinaDisplay::Subjects::NameSubjectPart,
  "conference" => CocinaDisplay::Subjects::NameSubjectPart,
  "event" => CocinaDisplay::Subjects::NameSubjectPart,
  "name" => CocinaDisplay::Subjects::NameSubjectPart,
  "title" => CocinaDisplay::Subjects::TitleSubjectPart,
  "time" => CocinaDisplay::Subjects::TemporalSubjectPart,
  "area" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "city" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "city section" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "continent" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "country" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "county" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "coverage" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "extraterrestrial area" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "island" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "place" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "region" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "state" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "territory" => CocinaDisplay::Subjects::PlaceSubjectPart,
  "point coordinates" => CocinaDisplay::Subjects::CoordinatesSubjectPart,
  "map coordinates" => CocinaDisplay::Subjects::CoordinatesSubjectPart,
  "bounding box coordinates" => CocinaDisplay::Subjects::CoordinatesSubjectPart
}.freeze
