require_relative "utils"
require_relative "contributor"
require_relative "title_builder"
require_relative "dates/date"

module CocinaDisplay
  # Base class for subjects in Cocina structured data.
  class Subject
    attr_reader :cocina

    # Extract the type of the subject from the Cocina structured data.
    # If no top-level type, uses the first structuredValue type.
    # @param cocina [Hash] The Cocina structured data for the subject.
    # @return [String, nil] The type of the subject, or nil if none
    # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#subject-types
    def self.detect_type(cocina)
      cocina["type"] || Utils.flatten_nested_values(cocina).pick("type")
    end

    # Choose and create the appropriate Subject subclass based on type.
    # @param cocina [Hash] The Cocina structured data for the subject.
    # @return [Subject]
    # @see detect_type
    def self.from_cocina(cocina)
      case detect_type(cocina)
      when "person", "family", "organization", "conference", "event", "name"
        NameSubject.new(cocina)
      when "title"
        TitleSubject.new(cocina)
      when "time"
        TemporalSubject.new(cocina)
      # TODO: special handling for geospatial subjects
      # when "map coordinates", "bounding box coordinates", "point coordinates"
      else
        Subject.new(cocina)
      end
    end

    # Initialize a Subject object with Cocina structured data.
    # @param cocina [Hash] The Cocina structured data for the subject.
    def initialize(cocina)
      @cocina = cocina
    end

    # The type of the subject.
    # If no top-level type, uses the first structuredValue type.
    # @return [String, nil] The type of the subject, or nil if none
    # @see detect_type
    def type
      self.class.detect_type(cocina)
    end

    # A string representation of the subject, formatted for display.
    # Concatenates any structured values with an appropriate delimiter.
    # Subclasses may override this for more specific formatting.
    # @return [String]
    def display_str
      Utils.compact_and_join(descriptive_values, delimiter: delimiter)
    end

    private

    # Flatten any structured values into an array of Hashes with "value" keys.
    # If no structured values, will return the top-level cocina data.
    # @see Utils.flatten_nested_values
    # @return [Array<Hash>] An array of Hashes representing all values.
    def descriptive_values
      Utils.flatten_nested_values(cocina).pluck("value")
    end

    # Delimiter to use for joining structured subject values.
    # LCSH uses a comma (the default); catalog headings use " > ".
    # @return [String]
    def delimiter
      if cocina["displayLabel"]&.downcase == "catalog heading"
        " > "
      else
        ", "
      end
    end
  end

  # A subject representing a named entity.
  class NameSubject < Subject
    attr_reader :name

    # Initialize a NameSubject object with Cocina structured data.
    # @param cocina [Hash] The Cocina structured data for the subject.
    def initialize(cocina)
      super
      @name = Contributor::Name.new(cocina)
    end

    # Use the contributor name formatting rules for display.
    # @return [String] The formatted name string, including life dates
    # @see CocinaDisplay::Contributor::Name#display_str
    def display_str
      @name.display_str(with_date: true)
    end
  end

  # A subject representing an entity with a title.
  class TitleSubject < Subject
    # Construct a title string to use for display.
    # @see CocinaDisplay::TitleBuilder.build
    # @note Unclear how often structured title subjects occur "in the wild".
    # @return [String]
    def display_str
      TitleBuilder.build([cocina])
    end
  end

  # A subject representing a date and/or time.
  class TemporalSubject < Subject
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
