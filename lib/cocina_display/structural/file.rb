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
    end
  end
end
