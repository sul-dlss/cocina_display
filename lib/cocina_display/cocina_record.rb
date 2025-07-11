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
require_relative "concerns/access"
require_relative "concerns/subjects"

module CocinaDisplay
  # Public Cocina metadata for an SDR object, as fetched from PURL.
  class CocinaRecord
    include CocinaDisplay::Concerns::Events
    include CocinaDisplay::Concerns::Contributors
    include CocinaDisplay::Concerns::Identifiers
    include CocinaDisplay::Concerns::Titles
    include CocinaDisplay::Concerns::Access
    include CocinaDisplay::Concerns::Subjects

    # Fetch a public Cocina document from PURL and create a CocinaRecord.
    # @note This is intended to be used in development or testing only.
    # @param druid [String] The bare DRUID of the object to fetch.
    # @return [CocinaDisplay::CocinaRecord]
    # :nocov:
    def self.fetch(druid)
      new(Net::HTTP.get(URI("https://purl.stanford.edu/#{druid}.json")))
    end
    # :nocov:

    # The parsed Cocina document.
    # @return [Hash]
    attr_reader :cocina_doc

    def initialize(cocina_json)
      @cocina_doc = JSON.parse(cocina_json)
    end

    # Evaluate a JSONPath expression against the Cocina document.
    # @return [Enumerator] An enumerator that yields results matching the expression.
    # @param path_expression [String] The JSONPath expression to evaluate.
    # @see https://www.rubydoc.info/gems/janeway-jsonpath/0.6.0/file/README.md
    # @example Name values for contributors
    #  record.path("$.description.contributor[*].name[*].value").search #=> ["Smith, John", "ACME Corp."]
    # @example Filtering nodes using a condition
    #  record.path("$.description.contributor[?(@.type == 'person')].name[*].value").search #=> ["Smith, John"]
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
    # @return [String]
    # @see https://github.com/sul-dlss/cocina-models/blob/main/openapi.yml#L532-L546
    # @example
    #  record.content_type #=> "image"
    def content_type
      cocina_doc["type"].split("/").last
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

    # Traverse nested FileSets and return an enumerator over their files.
    # Each file is a +Hash+.
    # @return [Enumerator] Enumerator over file hashes
    # @example
    #  record.files.each do |file|
    #   puts file["filename"] #=> "image1.jpg"
    #   puts file["size"] #=> 123456
    #  end
    def files
      path("$.structural.contains[*].structural.contains[*]")
    end
  end
end
