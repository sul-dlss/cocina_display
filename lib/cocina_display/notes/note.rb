module CocinaDisplay
  module Notes
    # A note associated with a cocina record
    class Note < Parallel::Parallel
      # Use the main parallel value to identify the type of note.
      delegate :abstract?, :general_note?, :preferred_citation?, :table_of_contents?, :part?, to: :main_value

      # Display methods reference the main note value. For parallel values,
      # see #translated_value and #transliterated_value.
      delegate :to_s, :values, :values_by_type, to: :main_value

      # Label used to render the note for display.
      # Uses a displayLabel if available, otherwise tries to look up via type.
      # Falls back to a default label derived from the type or a generic note label if
      # no type is set.
      # @return [String]
      def label
        display_label ||
          I18n.t(type&.parameterize&.underscore, default: default_label, scope: "cocina_display.field_label.note")
      end

      private

      # The class to use for parallel values.
      # @return [Class]
      def parallel_value_class
        NoteValue
      end

      # The default label for the note if no i18n key exists.
      # @return [String]
      def default_label
        type&.capitalize || I18n.t("cocina_display.field_label.note.note")
      end
    end
  end
end
