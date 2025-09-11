module CocinaDisplay
  module Description
    class Url < Access
      # The display label for the URL access metadata.
      # @return [String]
      def label
        I18n.t(:url, scope: "cocina_display.field_label.access")
      end

      # The link text for the URL access metadata.
      # @return [String, nil]
      def link_text
        cocina["displayLabel"].presence
      end
    end
  end
end
