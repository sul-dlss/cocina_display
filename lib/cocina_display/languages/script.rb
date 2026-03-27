module CocinaDisplay
  module Languages
    # A script used to write a Language.
    class Script
      attr_reader :cocina

      def initialize(cocina)
        @cocina = cocina
      end

      # The script code, e.g. an ISO 15924 code like "Latn" or "Cyrl".
      # @return [String, nil]
      def code
        cocina["code"]
      end

      # True if the script is Latin.
      # @return [Boolean]
      def latin?
        code == "Latn"
      end
    end
  end
end
