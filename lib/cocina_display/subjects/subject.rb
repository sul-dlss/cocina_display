module CocinaDisplay
  module Subjects
    # A Subject in Cocina structured data, possibly in multiple languages.
    class Subject < Parallel::Parallel
      # String representation and parts reference the main parallel value.
      delegate :to_s, :delimiter, :subject_parts, :values, to: :main_value

      # Label used when displaying the Subject.
      # @return [String]
      def label
        display_label || type_label
      end

      private

      # The class to use for the parallel values that make up this subject.
      # @return [Class]
      def parallel_value_class
        SubjectValue
      end

      # Type-specific label for this subject.
      # @return [String]
      def type_label
        I18n.t(type&.parameterize&.underscore, default: :subject, scope: "cocina_display.field_label.subject")
      end
    end
  end
end
