module CocinaDisplay
  module Structural
    # Represents a set of files in a Cocina object.
    class FileSet
      # Underlying hash parsed from Cocina JSON.
      attr_reader :cocina

      # Initialize the FileSet with Cocina structural data.
      # @param cocina [Hash] Cocina structured data for a single FileSet
      def initialize(cocina)
        @cocina = cocina
      end

      # The declared type of the FileSet, like "image" or "document".
      # @note This can differ from the contained file types.
      # @return [String, nil]
      def type
        cocina["type"]&.delete_prefix("https://cocina.sul.stanford.edu/models/resources/")
      end

      # All files contained in this FileSet.
      # @return [Array<CocinaDisplay::Structural::File>]
      def files
        Array(cocina.dig("structural", "contains")).map { |file| CocinaDisplay::Structural::File.new(file) }
      end
    end
  end
end
