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

      # Structured data for all file sets in the object.
      # Each fileset contains one or more files.
      # @return [Array<Hash>]
      # @example
      #  record.filesets.each do |fileset|
      #   puts fileset["type"] #=> "image"
      #   puts fileset["label"] #=> "High Resolution Images"
      #  end
      def filesets
        @filesets ||= path("$.structural.contains.*").search
      end

      # All unique MIME types of files in this object.
      # @return [Array<String>]
      # @example ["image/jpeg", "application/pdf"]
      def file_mime_types
        files.pluck("hasMimeType").uniq
      end

      # All unique types of filesets in this object.
      # @return [Array<String>]
      # @example ["image", "document"]
      def fileset_types
        filesets.pluck("type")
          .map { |type| type.delete_prefix("https://cocina.sul.stanford.edu/models/resources/") }
          .uniq
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

      # DRUIDs of collections this object is a member of.
      # @return [Array<String>]
      # @example ["sj775xm6965"]
      def containing_collections
        path("$.structural.isMemberOf.*").map { |druid| druid.delete_prefix("druid:") }
      end

      # Whether this object is a virtual object.
      # @return [Boolean]
      def virtual_object?
        return false if filesets.any?

        path("$.structural.hasMemberOrders.*.members.*").any?
      end

      # DRUIDs of members of this virtual object.
      # @return [Array<String>]
      # @example ["ts786ny5936", "tp006ms8736", "tj297ys4758"]
      def virtual_object_members
        return [] unless virtual_object?

        path("$.structural.hasMemberOrders.*.members.*").map { |druid| druid.delete_prefix("druid:") }
      end

      # DRUIDs of virtual objects this object is a part of.
      # @return [Array<String>]
      # @example "hj097bm8879"
      def virtual_object_parents
        related_resources.filter { |res| res.type == "part of" }.map(&:druid).compact_blank
      end
    end
  end
end
