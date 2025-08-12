require "active_support/number_helper/number_to_human_size_converter"

module CocinaDisplay
  module Concerns
    # Methods for inspecting structural metadata (e.g. file hierarchy)
    module Structural
      # Structured data for all individual files in the object.
      # Traverses nested FileSet structure to return a flattened array.
      # @return [Array<Hash>]
      # @example
      #  record.files.each do |file|
      #   puts file["filename"] #=> "image1.jpg"
      #   puts file["size"] #=> 123456
      #  end
      def files
        @files ||= path("$.structural.contains.*.structural.contains.*").search
      end

      # All unique MIME types of files in this object.
      # @return [Array<String>]
      # @example ["image/jpeg", "application/pdf"]
      def file_mime_types
        files.pluck("hasMimeType").uniq
      end

      # Human-readable string representation of {total_file_size_int}.
      # @return [String]
      # @example "2.5 MB"
      def total_file_size_str
        ActiveSupport::NumberHelper.number_to_human_size(total_file_size_int)
      end

      # Summed size of all files in bytes.
      # @return [Integer]
      # @example 2621440
      def total_file_size_int
        files.pluck("size").sum
      end
    end
  end
end
