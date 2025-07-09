# frozen_string_literal: true

require "janeway"
require "json"
require "net/http"
require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/conversions"

require_relative "title_builder"
require_relative "concerns/events"
require_relative "concerns/contributors"
require_relative "concerns/identifiers"

module CocinaDisplay
  # Public Cocina metadata for an SDR object, as fetched from PURL.
  class CocinaRecord
    include CocinaDisplay::Concerns::Events
    include CocinaDisplay::Concerns::Contributors
    include CocinaDisplay::Concerns::Identifiers

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

    # True if the object is a collection.
    # @return [Boolean]
    def collection?
      content_type == "collection"
    end

    # The main title for the object.
    # @note If you need more formatting control, consider using {CocinaDisplay::TitleBuilder} directly.
    # @return [String]
    # @example
    #   record.title #=> "Bugatti Type 51A. Road & Track Salon January 1957"
    def title
      CocinaDisplay::TitleBuilder.build(
        cocina_doc.dig("description", "title"),
        catalog_links: cocina_doc.dig("identification", "catalogLinks")
      )
    end

    # Alternative or translated titles for the object. Does not include the main title.
    # @return [Array<String>]
    # @example
    #  record.additional_titles #=> ["Alternate title 1", "Alternate title 2"]
    def additional_titles
      CocinaDisplay::TitleBuilder.additional_titles(
        cocina_doc.dig("description", "title")
      )
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

    # The PURL URL for this object.
    # @return [String]
    # @example
    #  record.purl_url #=> "https://purl.stanford.edu/bx658jh7339"
    def purl_url
      cocina_doc.dig("description", "purl") || "https://purl.stanford.edu/#{bare_druid}"
    end

    # The URL to the PURL environment this object is from.
    # @note Objects accessed via UAT will still have a production PURL base URL.
    # @return [String]
    # @example
    #   record.purl_base_url #=> "https://purl.stanford.edu"
    def purl_base_url
      URI(purl_url).origin
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
      else
        "https://stacks.stanford.edu"
      end
    end

    # The oEmbed URL for the object, optionally with additional parameters.
    # Corresponds to the PURL environment.
    # @param params [Hash] Additional parameters to include in the oEmbed URL.
    # @return [String]
    # @return [nil] if the object is a collection.
    # @example Generate an oEmbed URL for the viewer and hide the title
    #   record.oembed_url(hide_title: true) #=> "https://purl.stanford.edu/bx658jh7339/embed.json?hide_title=true"
    def oembed_url(params: {})
      return if collection?

      params[:url] ||= purl_url
      "#{purl_base_url}/embed.json?#{params.to_query}"
    end

    # The download URL to get the entire object as a .zip file.
    # Stacks generates the .zip for the object on request.
    # @return [String]
    # @example
    #   record.download_url #=> "https://stacks.stanford.edu/object/bx658jh7339"
    def download_url
      "#{stacks_base_url}/object/#{bare_druid}"
    end

    # The IIIF manifest URL for the object.
    # PURL generates the IIIF manifest.
    # @param version [Integer] The IIIF presentation spec version to use (3 or 2).
    # @return [String]
    # @example
    #  record.iiif_manifest_url #=> "https://purl.stanford.edu/bx658jh7339/iiif3/manifest"
    def iiif_manifest_url(version: 3)
      iiif_path = (version == 3) ? "iiif3" : "iiif"
      "#{purl_url}/#{iiif_path}/manifest"
    end
  end
end
