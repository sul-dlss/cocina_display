# frozen_string_literal: true

require "cocina/models"
require "janeway"

module CocinaDisplay
  # Public Cocina metadata for an SDR object
  class CocinaRecord
    attr_reader :cocina_doc

    def initialize(cocina_json)
      @cocina_doc = JSON.parse(cocina_json)
    end

    def path(path_expression)
      Janeway.enum_for(path_expression, cocina_doc)
    end

    def druid
      cocina_doc["externalIdentifier"]
    end

    def bare_druid
      druid.delete_prefix("druid:")
    end

    # The DOI for the object, just the identifier part. "10.25740/ppax-bf07"
    def doi
      doi_id = path("$.identification.doi").first ||
        path("$.description.identifier[?match(@.type, 'doi|DOI')].value").first ||
        path("$.description.identifier[?search(@.uri, 'doi.org')].uri").first

      URI(doi_id).path.delete_prefix("/") if doi_id.present?
    end

    # DOI as a URL. Any valid DOI should resolve via doi.org.
    def doi_url
      URI.join("https://doi.org", doi).to_s if doi.present?
    end

    # Item might still be in Searchworks under its druid instead.
    def folio_hrid
      path("$.identification.catalogLinks[?(@.catalog == 'folio')].catalogRecordId").first
    end

    # Does not imply the item is actually released to Searchworks!
    def searchworks_id
      folio_hrid || bare_druid
    end

    # This is for the metadata itself, not the object
    def created_time
      Time.parse(cocina_doc["created"])
    end

    # This is for the metadata itself, not the object
    def modified_time
      Time.parse(cocina_doc["modified"])
    end

    # "image", "map", "book", etc.
    def content_type
      cocina_doc["type"].split("/").last
    end

    def collection?
      content_type == "collection"
    end

    # Flatten nested FileSet structure to get all files in the object
    # @return [Enumerator[Hash]] Array of File objects
    def files
      path("$.structural.contains[*].structural.contains[*]")
    end

    # The PURL URL for the object
    def purl_url
      cocina_doc.dig("description", "purl") || "https://purl.stanford.edu/#{bare_druid}"
    end

    # The URL to the PURL environment this object is from
    # NOTE: objects accessed via UAT will still have a production PURL URL
    def purl_base_url
      URI(purl_url).origin
    end

    # The URL to the stacks environment this object is shelved in
    # Corresponds to the PURL environment
    def stacks_base_url
      if purl_base_url == "https://sul-purl-stage.stanford.edu"
        "https://sul-stacks-stage.stanford.edu"
      else
        "https://stacks.stanford.edu"
      end
    end

    # The oEmbed URL for the object, optionally with additional params
    # PURL generates the oEmbed response
    # @param params [Hash] Additional parameters to include in the oEmbed URL
    def oembed_url(params: {})
      return if collection?

      params[:url] ||= purl_url
      "#{purl_base_url}/embed.json?#{params.to_query}"
    end

    # The download URL to get the entire object as a .zip file
    # Stacks generates the .zip for the object
    def download_url
      "#{stacks_base_url}/object/#{bare_druid}"
    end

    # The IIIF manifest URL for the object, version 3 by default
    # PURL generates the IIIF manifest
    # @param version [Integer] The IIIF version to use (3 or 2)
    def iiif_manifest_url(version: 3)
      iiif_path = (version == 3) ? "iiif3" : "iiif"
      "#{purl_url}/#{iiif_path}/manifest"
    end
  end
end
