module CocinaDisplay
  module Forms
    # A Resource Type form associated with part or all of a Cocina object.
    class ResourceType < Form
      # Resource types are lowercased for display, except self-deposit types.
      # @return [String]
      def to_s
        stanford_self_deposit? ? flat_value : flat_value.downcase
      end

      # For self-deposit resource types, the flat value comprises primary and any subtypes.
      # @return [String]
      def flat_value
        return super unless stanford_self_deposit?
        return primary_type unless subtypes.any?

        "#{primary_type} (#{subtypes.join(", ")})"
      end

      # Is this a Stanford self-deposit resource type?
      # @note These are handled separately when displayed.
      # @return [Boolean]
      def stanford_self_deposit?
        source == "Stanford self-deposit resource types"
      end

      # Is this a MODS resource type?
      # @return [Boolean]
      def mods?
        source == "MODS resource types"
      end

      private

      # @return [String]
      def source
        cocina.dig("source", "value")
      end

      # Stanford self-deposit resource types are labeled "Genre".
      # @return [String]
      def type_label
        (I18n.t("cocina_display.field_label.form.genre") if stanford_self_deposit?) || super
      end

      # The primary type, if this is a structured self-deposit resource type.
      # @return [String, nil]
      def primary_type
        type_components["type"].first
      end

      # The subtypes, if this is a structured self-deposit resource type.
      # @return [Array<String>]
      def subtypes
        type_components["subtype"] || []
      end

      # A hash containing the destructured resource type and subtypes, if any.
      # @return [Hash<String, Array<String>>]
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#form-part-types-for-structured-value
      # @note Only used by self-deposit resource types.
      def type_components
        Utils.flatten_nested_values(cocina).each_with_object({}) do |node, hash|
          type = node["type"]
          hash[type] ||= []
          hash[type] << node["value"]
        end.compact_blank
      end
    end
  end
end
