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

module CocinaDisplay
  # Public Cocina metadata for an SDR object, as fetched from PURL.
  class CocinaRecord
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

    # The parsed Cocina document.
    # @return [Hash]
    attr_reader :cocina_doc

    # Initialize a CocinaRecord with a Cocina document hash.
    # @param cocina_doc [Hash]
    def initialize(cocina_doc)
      @cocina_doc = cocina_doc
    end

    # Evaluate a JSONPath expression against the Cocina document.
    # @return [Enumerator] An enumerator that yields results matching the expression.
    # @param path_expression [String] The JSONPath expression to evaluate.
    # @see https://www.rubydoc.info/gems/janeway-jsonpath/0.6.0/file/README.md
    # @example Name values for contributors
    #  record.path("$.description.contributor.*.name.*.value").search #=> ["Smith, John", "ACME Corp."]
    # @example Filtering nodes using a condition
    #  record.path("$.description.contributor[?(@.type == 'person')].name.*.value").search #=> ["Smith, John"]
    def path(path_expression)
      Janeway.enum_for(path_expression, cocina_doc)
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
      cocina_doc["type"]&.split("/")&.last
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

  # A resource related to the record; behaves like a CocinaRecord.
  # @note Related resources have no structural metadata.
  class RelatedResource < CocinaRecord
    # Description of the relation to the source record.
    # @return [String]
    # @example "is part of"
    # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#relatedresource-types
    attr_reader :type

    # Restructure the hash so that everything is under "description" key, since
    # it's all descriptive metadata. This makes most CocinaRecord methods work.
    def initialize(cocina_doc)
      @type = cocina_doc["type"]
      @cocina_doc = {"description" => cocina_doc.except("type")}
    end
  end
end
