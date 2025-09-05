module CocinaDisplay
  module Subjects
    # Base class for subjects in Cocina structured data.
    class Subject
      attr_reader :cocina

      # Initialize a Subject object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the subject.
      def initialize(cocina)
        @cocina = cocina
      end

      # The top-level type of the subject.
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#subject-types
      # @return [String, nil]
      def type
        cocina["type"]
      end

      # Array of display strings for each value in the subject.
      # Used for search, where each value should be indexed separately.
      # @return [Array<String>]
      def display_values
        subject_values.map(&:to_s).compact_blank
      end

      # The value to use for display.
      # Genre values are capitalized; other subject values are not.
      # @return [String]
      def to_s
        (type == "genre") ? display_value&.upcase_first : display_value
      end

      # A string representation of the entire subject, concatenated for display.
      # @return [String]
      def display_value
        Utils.compact_and_join(display_values, delimiter: " > ")
      end

      # Label used to render the subject for display.
      # Uses a displayLabel if available, otherwise looks up via type.
      # @return [String]
      def label
        cocina["displayLabel"].presence || type_label
      end

      # Individual values composing this subject.
      # Can be multiple if the Cocina featured nested data.
      # If no type was specified on a value, uses the top-level subject type.
      # @return [Array<SubjectValue>]
      def subject_values
        @subject_values ||= Utils.flatten_nested_values(cocina, atomic_types: SubjectValue.atomic_types).map do |value|
          subject_value = SubjectValue.from_cocina(value)
          subject_value.type ||= type
          subject_value
        end
      end

      private

      # Type-specific label for this subject.
      # @return [String]
      def type_label
        I18n.t(type&.parameterize&.underscore, default: :subject, scope: "cocina_display.field_label.subject")
      end
    end
  end
end
