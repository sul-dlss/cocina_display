# frozen_string_literal: true

module CocinaDisplay
  # A "meta_json" document that records release metadata for an SDR object.
  class MetaRecord
    # Fetch a public "meta_json" document from PURL and create a MetaRecord.
    # These records hold release metadata for a Cocina object.
    # @param druid [String] The bare DRUID of the object to fetch.
    # @param purl_url [String] The base url for the purl service.
    # @return [CocinaDisplay::MetaRecord]
    def self.fetch(druid, purl_url: "https://purl.stanford.edu")
      response = Net::HTTP.get_response(URI("#{purl_url}/#{druid}.meta_json"))
      new(JSON.parse(response.body)) if response.is_a?(Net::HTTPSuccess)
    end

    attr_reader :meta_doc

    # Create a MetaRecord from a meta_json document hash.
    # @param meta_doc [Hash<String, String>] The meta_json document hash
    def initialize(meta_doc)
      @meta_doc = meta_doc
    end

    # Determine if the object is released to a given target.
    # @param target [Symbol|String] The release target to check.
    # @return [Boolean] True if the object is released to the target, false otherwise
    # @return [NilClass] If the target is not present in the release metadata
    def released_to?(target)
      meta_doc[target.to_s]
    end

    # Is the object released to the PURL sitemap?
    # @return [Boolean]
    def released_to_sitemap?
      released_to?(:sitemap)
    end

    # Is the object released to Searchworks?
    # @return [Boolean]
    def released_to_searchworks?
      released_to?(:searchworks)
    end

    # Is the object released to Earthworks?
    # @return [Boolean]
    def released_to_earthworks?
      released_to?(:earthworks)
    end
  end
end
