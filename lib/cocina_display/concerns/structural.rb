require "active_support/number_helper/number_to_human_size_converter"

module CocinaDisplay
  module Concerns
    # Methods for inspecting structural metadata (e.g. file hierarchy)
    module Structural
      # Structured data for all file sets in the object.
      # Each fileset contains one or more files.
      # @return [Array<CocinaDisplay::Structural::FileSet>]
      # @example
      #  record.filesets.each do |fileset|
      #   puts fileset.type #=> "image"
      #   puts fileset.label #=> "High Resolution Images"
      #  end
      def filesets
        @filesets ||= path("$.structural.contains.*").map do |fileset|
          CocinaDisplay::Structural::FileSet.new(fileset)
        end
      end

      # Structured data for all individual files in the object.
      # Traverses nested FileSet structure to return a flattened array.
      # @return [Array<CocinaDisplay::Structural::File>]
      # @example
      #  record.files.each do |file|
      #   puts file.filename #=> "image1.jpg"
      #   puts file.size #=> 123456
      #  end
      def files
        filesets.flat_map(&:files)
      end

      # All unique MIME types of files in this object.
      # @return [Array<String>]
      # @example ["image/jpeg", "application/pdf"]
      def file_mime_types
        files.map(&:mime_type).compact.uniq
      end

      # All unique types of filesets in this object.
      # @return [Array<String>]
      # @example ["image", "document"]
      def fileset_types
        filesets.map(&:type).compact.uniq
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
        files.map(&:size).compact.sum
      end

      # URL to a thumbnail image for this object, if any.
      # @note Uses the IIIF image server to generate an image of the given size.
      # @return [String, nil]
      # @example "https://stacks.stanford.edu/image/iiif/ts786ny5936%2FPC0170_s1_E_0204.jp2/full/400,400/0/default.jpg"
      def thumbnail_url(base_url: stacks_base_url, height: 400, width: 400)
        thumbnail_file&.iiif_url(base_url: base_url, height: height, width: width)
      end

      # True if the object has a usable thumbnail file.
      # @note Does not attempt to crawl virtual object members for thumbnails.
      # @return [Boolean]
      def thumbnail?
        thumbnail_file.present?
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

      # The thumbnail file for this object, if any.
      # Prefers files marked as thumbnails; falls back to any JP2 image.
      # @return [CocinaDisplay::Structural::File, nil]
      def thumbnail_file
        files.find(&:thumbnail?) || files.find(&:jp2_image?)
      end
    end
  end
end
