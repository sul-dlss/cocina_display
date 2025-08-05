require_relative "subject"
require_relative "../contributors/name"
require_relative "../title_builder"
require_relative "../dates/date"

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
        SUBJECT_VALUE_TYPES.keys
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
      def display_str
        cocina["value"]
      end

      # True if the subject value is a place.
      # @see PLACE_SUBJECT_TYPES
      # @return [Boolean]
      def place?
        PLACE_SUBJECT_TYPES.include?(type)
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
      # @see CocinaDisplay::Contributor::Name#display_str
      def display_str
        @name.display_str(with_date: true)
      end
    end

    # A subject value representing an entity with a title.
    class TitleSubjectValue < SubjectValue
      # Construct a title string to use for display.
      # @see CocinaDisplay::TitleBuilder.build
      # @note Unclear how often structured title subjects occur "in the wild".
      # @return [String]
      def display_str
        TitleBuilder.build([cocina])
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
      def display_str
        @date.qualified_value
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
  "time" => CocinaDisplay::Subjects::TemporalSubjectValue
  # TODO: special handling for geospatial subjects
  # "map coordinates", "bounding box coordinates", "point coordinates"
}.freeze

# Subject types that are considered places.
PLACE_SUBJECT_TYPES = [
  "area",
  "city",
  "city section",
  "continent",
  "country",
  "county",
  "coverage",
  "extraterrestrial area",
  "island",
  "place",
  "region",
  "state",
  "territory"
].freeze
