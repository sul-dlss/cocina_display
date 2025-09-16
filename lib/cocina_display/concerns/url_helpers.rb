module CocinaDisplay
  module Concerns
    # Methods that generate URLs to access an object.
    module UrlHelpers
      # The PURL URL for this object.
      # @return [String]
      # @example
      #  record.purl_url #=> "https://purl.stanford.edu/bx658jh7339"
      def purl_url
        cocina_doc.dig("description", "purl")
      end

      # The oEmbed URL for the object, optionally with additional parameters.
      # Corresponds to the PURL environment.
      # @param params [Hash] Additional parameters to include in the oEmbed URL.
      # @return [String]
      # @return [nil] if the object is a collection.
      # @example Generate an oEmbed URL for the viewer and hide the title
      #   record.oembed_url(hide_title: true) #=> "https://purl.stanford.edu/bx658jh7339/embed.json?hide_title=true"
      def oembed_url(params: {})
        return if (!is_a?(CocinaDisplay::RelatedResource) && collection?) || purl_url.blank?

        params[:url] ||= purl_url
        "#{purl_base_url}/embed.json?#{params.to_query}"
      end

      # The download URL to get the entire object as a .zip file.
      # Stacks generates the .zip for the object on request.
      # @return [String]
      # @example
      #   record.download_url #=> "https://stacks.stanford.edu/object/bx658jh7339"
      def download_url
        "#{stacks_base_url}/object/#{bare_druid}" if bare_druid.present?
      end

      # The IIIF manifest URL for the object.
      # PURL generates the IIIF manifest.
      # @param version [Integer] The IIIF presentation spec version to use (3 or 2).
      # @return [String]
      # @example
      #  record.iiif_manifest_url #=> "https://purl.stanford.edu/bx658jh7339/iiif3/manifest"
      def iiif_manifest_url(version: 3)
        iiif_path = (version == 3) ? "iiif3" : "iiif"
        "#{purl_url}/#{iiif_path}/manifest" if purl_url.present?
      end

      private

      # The URL to the PURL environment this object is from.
      # @note Objects accessed via UAT will still have a production PURL base URL.
      # @return [String]
      # @example
      #   record.purl_base_url #=> "https://purl.stanford.edu"
      def purl_base_url
        URI(purl_url).origin if purl_url.present?
      end

      # The URL to the stacks environment this object is shelved in.
      # Corresponds to the PURL environment.
      # @see purl_base_url
      # @return [String]
      # @example
      #  record.stacks_base_url #=> "https://stacks.stanford.edu"
      def stacks_base_url
        if purl_base_url == "https://sul-purl-stage.stanford.edu"
          "https://sul-stacks-stage.stanford.edu"
        elsif purl_base_url.present?
          "https://stacks.stanford.edu"
        end
      end
    end
  end
end
