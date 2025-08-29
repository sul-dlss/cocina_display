# frozen_string_literal: true

require "janeway"
require "json"
require "net/http"
require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/conversions"

require_relative "concerns/events"
require_relative "concerns/contributors"
require_relative "concerns/identifiers"
require_relative "concerns/titles"
require_relative "concerns/url_helpers"
require_relative "concerns/subjects"
require_relative "concerns/forms"
require_relative "concerns/languages"
require_relative "concerns/geospatial"
require_relative "concerns/structural"
require_relative "utils"
require_relative "json_backed_record"
require_relative "related_resource"

module CocinaDisplay
  # Public Cocina metadata for an SDR object, as fetched from PURL.
  class CocinaRecord < JsonBackedRecord
    include CocinaDisplay::Concerns::Events
    include CocinaDisplay::Concerns::Contributors
    include CocinaDisplay::Concerns::Identifiers
    include CocinaDisplay::Concerns::Titles
    include CocinaDisplay::Concerns::UrlHelpers
    include CocinaDisplay::Concerns::Subjects
    include CocinaDisplay::Concerns::Forms
    include CocinaDisplay::Concerns::Languages
    include CocinaDisplay::Concerns::Geospatial
    include CocinaDisplay::Concerns::Structural

    # Fetch a public Cocina document from PURL and create a CocinaRecord.
    # @note This is intended to be used in development or testing only.
    # @param druid [String] The bare DRUID of the object to fetch.
    # @param deep_compact [Boolean] If true, compact the JSON to remove blank values.
    # @return [CocinaDisplay::CocinaRecord]
    # :nocov:
    def self.fetch(druid, deep_compact: false)
      from_json(Net::HTTP.get(URI("https://purl.stanford.edu/#{druid}.json")), deep_compact: deep_compact)
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
      cocina_doc["type"].delete_prefix("https://cocina.sul.stanford.edu/models/")
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

    # Resources related to the object.
    # @return [Array<CocinaDisplay::RelatedResource>]
    def related_resources
      @related_resources ||= path("$.description.relatedResource[*]").map { |res| RelatedResource.new(res) }
    end
  end
end
