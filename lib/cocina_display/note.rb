module CocinaDisplay
  # A note associated with a cocina record
  class Note
    ABSTRACT_TYPES = ["summary", "abstract", "scope and content"].freeze
    ABSTRACT_DISPLAY_LABEL_REGEX = /Abstract|Summary|Scope and content/i
    PREFERRED_CITATION_TYPES = ["preferred citation"].freeze
    PREFERRED_CITATION_DISPLAY_LABEL_REGEX = /Preferred citation/i
    TOC_TYPES = ["table of contents"].freeze
    TOC_DISPLAY_LABEL_REGEX = /Table of contents/i

    attr_reader :cocina

    # Initialize a Note from Cocina structured data.
    # @param cocina [Hash]
    def initialize(cocina)
      @cocina = cocina
    end

    # String representation of the note.
    # @return [String, nil]
    def to_s
      cocina["value"].presence
    end

    # The type of the note, e.g. "abstract".
    # @return [String, nil]
    def type
      cocina["type"].presence
    end

    # The display label set in Cocina
    # @return [String, nil]
    def display_label
      cocina["displayLabel"].presence
    end

    # Label used to render the note for display.
    # Uses a displayLabel if available, otherwise tries to look up via type.
    # Falls back to a default label derived from the type or a generic note label if
    # no type is set.
    # @return [String]
    def label
      display_label ||
        I18n.t(type&.parameterize&.underscore, default: default_label, scope: "cocina_display.field_label.note")
    end

    # Check if the note is an abstract
    # @return [Boolean]
    def abstract?
      display_label&.match?(ABSTRACT_DISPLAY_LABEL_REGEX) ||
        ABSTRACT_TYPES.include?(type)
    end

    # Check if the note is a general note (not a table of contents, abstract, or preferred citation)
    # @return [Boolean]
    def general_note?
      !table_of_contents? && !abstract? && !preferred_citation?
    end

    # Check if the note is a preferred citation
    # @return [Boolean]
    def preferred_citation?
      display_label&.match?(PREFERRED_CITATION_DISPLAY_LABEL_REGEX) ||
        PREFERRED_CITATION_TYPES.include?(type)
    end

    # Check if the note is a table of contents
    # @return [Boolean]
    def table_of_contents?
      display_label&.match?(TOC_DISPLAY_LABEL_REGEX) ||
        TOC_TYPES.include?(type)
    end

    private

    def default_label
      type&.capitalize || I18n.t("cocina_display.field_label.note.note")
    end
  end
end
