module CocinaDisplay
  module Structural
    # Represents a set of files in a Cocina object.
    class FileSet
      # Underlying hash parsed from Cocina JSON.
      attr_reader :cocina

      # URL to Stacks environment that will serve this fileset.
      attr_reader :base_url

      # Initialize the FileSet with Cocina structural data.
      # @param cocina [Hash] Cocina structured data for a single FileSet
      # @param base_url [String] URL to Stacks environment that will serve this fileset
      # @param druid [String, nil] DRUID of the object this fileset belongs to
      def initialize(cocina, base_url: "https://stacks.stanford.edu", druid: nil)
        @cocina = cocina
        @base_url = base_url
        @druid = druid
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
        @files ||= Array(cocina.dig("structural", "contains")).map do |file|
          CocinaDisplay::Structural::File.new(file, base_url: base_url, druid: druid)
        end
      end

      private

      # DRUID of the object this fileset belongs to.
      # @note Inferred from the start of the externalIdentifier.
      # @return [String, nil]
      def druid
        @druid || external_id[/^[a-z]{2}\d{3}[a-z]{2}\d{4}/] if external_id.present?
      end

      # External identifier for the fileset, minus the URL prefix.
      # @return [String, nil]
      # @note Staging and production formats differ.
      # @example production
      #   "bk264hq9320-bk264hq9320_3"
      # @example staging
      #   "bh114dk3076_4"
      def external_id
        cocina["externalIdentifier"]&.delete_prefix("https://cocina.sul.stanford.edu/fileSet/")
      end
    end
  end
end
