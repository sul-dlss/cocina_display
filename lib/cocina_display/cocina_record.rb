# frozen_string_literal: true

module CocinaDisplay
  # Public Cocina metadata for an SDR object, as fetched from PURL.
  class CocinaRecord < JsonBackedRecord
    include CocinaDisplay::Concerns::Accesses
    include CocinaDisplay::Concerns::Events
    include CocinaDisplay::Concerns::Contributors
    include CocinaDisplay::Concerns::Identifiers
    include CocinaDisplay::Concerns::Notes
    include CocinaDisplay::Concerns::Titles
    include CocinaDisplay::Concerns::UrlHelpers
    include CocinaDisplay::Concerns::Subjects
    include CocinaDisplay::Concerns::Forms
    include CocinaDisplay::Concerns::Languages
    include CocinaDisplay::Concerns::Geospatial
    include CocinaDisplay::Concerns::Structural
    include CocinaDisplay::Concerns::RelatedResources

    # Fetch a public Cocina document from PURL and create a CocinaRecord.
    # @note This is intended to be used in development or testing only.
    # @param druid [String] The bare DRUID of the object to fetch.
    # @param purl_url [String] The base url for the purl service.
    # @param deep_compact [Boolean] If true, compact the JSON to remove blank values.
    # @return [CocinaDisplay::CocinaRecord]
    # :nocov:
    def self.fetch(druid, deep_compact: true, purl_url: "https://purl.stanford.edu")
      from_json(Net::HTTP.get(URI("#{purl_url}/#{druid}.json")), deep_compact: deep_compact)
    end
    # :nocov:

    # Create a CocinaRecord from a JSON string.
    # @param cocina_json [String]
    # @param deep_compact [Boolean] If true, compact the JSON to remove blank values.
    # @return [CocinaDisplay::CocinaRecord]
    def self.from_json(cocina_json, deep_compact: false)
      cocina_doc = JSON.parse(cocina_json)
      deep_compact ? new(Utils.deep_compact_blank(cocina_doc)) : new(cocina_doc)
    end

    # Timestamp when the Cocina was created.
    # @note This is for the metadata itself, not the object.
    # @return [Time]
    def created_time
      Time.parse(cocina_doc["created"])
    end

    # Timestamp when the Cocina was last modified.
    # @note This is for the metadata itself, not the object.
    # @return [Time]
    def modified_time
      Time.parse(cocina_doc["modified"])
    end

    # SDR content type of the object.
    # @note {RelatedResource}s may not have a content type.
    # @return [String, nil]
    # @see https://github.com/sul-dlss/cocina-models/blob/main/openapi.yml#L532-L546
    # @example
    #  record.content_type #=> "image"
    def content_type
      @content_type ||= cocina_doc["type"].delete_prefix("https://cocina.sul.stanford.edu/models/")
    end

    # Primary processing label for the object.
    # @note This may or may not be the same as the title.
    # @return [String, nil]
    def label
      cocina_doc["label"]
    end

    # True if the object is a collection.
    # @return [Boolean]
    def collection?
      content_type == "collection"
    end

    # Copyright statement from Cocina access metadata.
    # @return [String, nil]
    def copyright
      cocina_doc.dig("access", "copyright")
    end

    # Use and reproduction statement from Cocina access metadata.
    # @return [String, nil]
    def use_and_reproduction
      cocina_doc.dig("access", "useAndReproductionStatement")
    end

    # Description of the license
    # @return [String, nil]
    def license_description
      @license_description ||=
        license ? License.new(url: license).description : nil
    end

    # License URI
    # @return [String, nil]
    def license
      cocina_doc.dig("access", "license")
    end
  end
end
