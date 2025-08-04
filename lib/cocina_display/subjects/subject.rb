require_relative "../utils"
require_relative "subject_value"

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
        subject_values.map(&:display_str).compact_blank
      end

      # A string representation of the entire subject, concatenated for display.
      # @return [String]
      def display_str
        Utils.compact_and_join(display_values, delimiter: " > ")
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
    end
  end
end
