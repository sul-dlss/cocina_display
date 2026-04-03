module CocinaDisplay
  module Subjects
    # A subject in Cocina structured data in a single language/script.
    class SubjectValue < Parallel::ParallelValue
      # Array of display strings for each part of the subject.
      # Used for search, where each value should be indexed separately.
      # @return [Array<String>]
      def values
        subject_parts.map(&:to_s).compact_blank
      end

      # The value to use for display.
      # Genre values are capitalized; other subject values are not.
      # @return [String]
      def to_s
        (type == "genre") ? flat_value&.upcase_first : flat_value
      end

      # A string representation of the entire subject, concatenated for display.
      # @return [String]
      def flat_value
        Utils.compact_and_join(values, delimiter: delimiter)
      end

      # Delimiter used to join the individual parts of the subject for display.
      # @return [String]
      def delimiter
        " > "
      end

      # Individual SubjectParts composing this subject.
      # Can be multiple if the Cocina featured structuredValues.
      # All SubjectParts inherit the type of their parent Subject.
      # @return [Array<SubjectPart>]
      def subject_parts
        @subject_parts ||= if SubjectPart.atomic_types.include?(type)
          SubjectPart.from_cocina(cocina, type: type)
        else
          Utils.flatten_nested_values(cocina, atomic_types: SubjectPart.atomic_types).flat_map do |value|
            SubjectPart.from_cocina(value, type: value["type"] || type)
          end
        end
      end
    end
  end
end
