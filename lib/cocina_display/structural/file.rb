module CocinaDisplay
  module Structural
    # Represents a single file in a Cocina object.
    class File
      # Underlying hash parsed from Cocina JSON.
      attr_reader :cocina

      # Initialize the File with Cocina file data.
      # @param cocina [Hash] Cocina structured data for a single file
      def initialize(cocina)
        @cocina = cocina
      end

      # The name of the file on disk, including file extension.
      # @return [String, nil]
      # @example "bc798xr9549_30C_Kalsang_Yulgial_thumb.jp2"
      def filename
        cocina["filename"]
      end

      # The MIME type of the file.
      # @return [String, nil]
      # @example "image/jp2"
      def mime_type
        cocina["hasMimeType"]
      end

      # The relation of the file to the object.
      # @return [String, nil]
      # @example "thumbnail"
      def use
        cocina["use"]
      end

      # The size in bytes of the file.
      # @return [Integer, nil]
      # @example 204800
      def size
        cocina["size"]
      end

      # True if this file was marked as a thumbnail and has nonzero dimensions.
      # @return [Boolean]
      def thumbnail?
        use == "thumbnail" && nonzero_dimensions?
      end

      # True if this file is a JP2 image and has nonzero dimensions.
      # @return [Boolean]
      def jp2_image?
        mime_type == "image/jp2" && nonzero_dimensions?
      end

      # True if file is an image with nonzero height and width.
      # @return [Boolean]
      def nonzero_dimensions?
        height&.positive? && width&.positive?
      end

      # The height of the image in pixels, if applicable.
      # @return [Integer, nil]
      def height
        cocina.dig("presentation", "height").to_i
      end

      # The width of the image in pixels, if applicable.
      # @return [Integer, nil]
      def width
        cocina.dig("presentation", "width").to_i
      end

      # Generate a IIIF image URL for this file.
      # @param base_url [String] Base URL for the IIIF image server.
      # @param region [String] Desired region of the image (e.g., "full", "square", "x,y,w,h", "pct:x,y,w,h").
      # @param width [String] Desired width of the image in pixels (use "!" prefix to preserve aspect ratio).
      # @param height [String] Desired height of the image in pixels.
      # @return [String, nil]
      # @example "https://stacks.stanford.edu/image/iiif/ts786ny5936%2FPC0170_s1_E_0204.jp2/full/!400,400/0/default.jpg"
      def iiif_url(base_url:, region: "full", width: "!400", height: "400")
        return unless base_url.present? && iiif_id.present?

        "#{base_url}/image/iiif/#{iiif_id}/#{region}/#{width},#{height}/0/default.jpg"
      end

      # For images served over IIIF, we encode the DRUID and filename as an identifier.
      # @return [String, nil]
      # @example "ts786ny5936%2FPC0170_s1_E_0204"
      def iiif_id
        ERB::Util.url_encode("#{druid}/#{filename.delete_suffix(".jp2")}") if druid.present? && filename.present?
      end

      private

      # External identifier for the file, including the DRUID and file ID.
      # @return [String, nil]
      # @example "ts786ny5936-ts786ny5936_1/PC0170_s1_E_0204.jp2"
      def external_id
        cocina["externalIdentifier"]&.delete_prefix("https://cocina.sul.stanford.edu/file/")
      end

      # The DRUID of the object this file belongs to.
      # @return [String, nil]
      def druid
        external_id.split("-").first if external_id.present?
      end
    end
  end
end
