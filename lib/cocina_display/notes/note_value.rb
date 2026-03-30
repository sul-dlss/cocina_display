module CocinaDisplay
  module Notes
    # A Note associated with an item in a single language.
    class NoteValue < Parallel::ParallelValue
      ABSTRACT_TYPES = ["summary", "abstract", "scope and content"].freeze
      ABSTRACT_DISPLAY_LABEL_REGEX = /Abstract|Summary|Scope and content/i
      PREFERRED_CITATION_TYPES = ["preferred citation"].freeze
      PREFERRED_CITATION_DISPLAY_LABEL_REGEX = /Preferred citation/i
      TOC_TYPES = ["table of contents"].freeze
      TOC_DISPLAY_LABEL_REGEX = /Table of contents/i

      # Custom label used when displaying the note, if any.
      # @return [String, nil]
      def label
        display_label || type_label
      end

      # The value to use for display.
      # @return [String, nil]
      def to_s
        flat_value
      end

      # Delimiter used to join multiple values for display.
      # @return [String, nil]
      def delimiter
        " -- " if table_of_contents?
      end

      # Does this note use a delimiter?
      # @return [Boolean]
      def delimited?
        delimiter.present?
      end

      # Check if the note is an abstract
      # @return [Boolean]
      def abstract?
        display_label&.match?(ABSTRACT_DISPLAY_LABEL_REGEX) ||
          ABSTRACT_TYPES.include?(type)
      end

      # Check if the note is a general note (not a table of contents, abstract, preferred citation, or part)
      # @return [Boolean]
      def general_note?
        !table_of_contents? && !abstract? && !preferred_citation? && !part?
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

      # Check if the note is a part note
      # @note These are combined with the title and not displayed separately.
      # @return [Boolean]
      def part?
        type == "part"
      end

      # Single concatenated string value for the note.
      # @return [String, nil]
      def flat_value
        Utils.compact_and_join(values, delimiter: delimiter || "").presence
      end

      # The raw values from the Cocina data, flattened if nested.
      # Strips excess whitespace and the delimiter if present.
      # Splits on the delimiter if it was already included in the values(s).
      # @return [Array<String>]
      def values
        Utils.flatten_nested_values(cocina).pluck("value")
          .map { |value| cleaned_value(value) }
          .flat_map { |value| delimited? ? value.split(delimiter.strip) : [value] }
          .map(&:strip)
          .compact_blank
      end

      # The raw values from the Cocina data as a hash with type as key.
      # Strips excess whitespace and the delimiter if present.
      # Splits on the delimiter if it was already included in the values(s).
      # @return [Hash{String => Array<String>}]
      def values_by_type
        Utils.flatten_nested_values(cocina).each_with_object({}) do |node, hash|
          value = cleaned_value(node["value"])
          (delimited? ? value.split(delimiter.strip) : [value]).each do |part|
            type = node["type"]
            hash[type] ||= []
            hash[type] << part.strip
          end
        end
      end

      private

      # Remove the delimiter from the ends of the value and strip whitespace.
      # @param value [String]
      # @return [String]
      def cleaned_value(value)
        return value.strip unless delimited?

        value.gsub(/\s*#{Regexp.escape(delimiter.strip)}\s*$/, " ")
          .gsub(/^\s*#{Regexp.escape(delimiter.strip)}\s*/, " ")
          .strip
      end

      # Type-specific label for the note, falling back to a generic "Note".
      # @return [String]
      def type_label
        I18n.t(type&.parameterize&.underscore, scope: "cocina_display.field_label.note", default: type.capitalize)
      end
    end
  end
end
