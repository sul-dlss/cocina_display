module CocinaDisplay
  module Forms
    # A Resource Type form associated with part or all of a Cocina object.
    class ResourceType < Form
      # Resource types are lowercased for display.
      # @return [String]
      def to_s
        super&.downcase
      end

      # Is this a Stanford self-deposit resource type?
      # @note These are handled separately when displayed.
      # @return [Boolean]
      def stanford_self_deposit?
        cocina.dig("source", "value") == "Stanford self-deposit resource types"
      end

      private

      # Stanford self-deposit resource types are labeled "Genre".
      # @return [String]
      def type_label
        (I18n.t("cocina_display.field_label.form.genre") if stanford_self_deposit?) || super
      end
    end
  end
end
