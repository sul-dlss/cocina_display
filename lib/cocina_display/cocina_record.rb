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

    # Only present if there is a FOLIO catalog link; item may still be in the
    # catalog under its DRUID. Ignores old (symphony) links.
    def catkey
      path("$.identification.catalogLinks[?(@.catalog == 'folio')].catalogRecordId").first
    end

    # Does not imply the item is actually released to Searchworks!
    def searchworks_id
      catkey || bare_druid
    end

    def created_time
      Time.parse(cocina_doc["created"])
    end

    def modified_time
      Time.parse(cocina_doc["modified"])
    end

    def content_type
      cocina_doc["type"].split("/").last
    end

    def collection?
      content_type == "collection"
    end

    # Flatten nested FileSet structure to get all files in the object
    # @return [Array[Hash]] Array of File objects
    def files
      path("$.structural.contains[*].structural.contains[*]")
    end

    # The PURL URL for the object
    # @param purl_base_url [String] Base URL for the PURL environment
    def purl_url(purl_base_url: "https://purl.stanford.edu")
      "#{purl_base_url}/#{bare_druid}"
    end

    # The oEmbed URL for the object, optionally with additional params
    # PURL generates the oEmbed response
    # @param purl_base_url [String] Base URL for the PURL environment
    def oembed_url(purl_base_url: "https://purl.stanford.edu", params: {})
      return if collection?

      params[:url] ||= purl_url(purl_base_url:)
      "#{purl_base_url}/embed.json?#{params.to_query}"
    end

    # The download URL to get the entire object as a .zip file
    # Stacks generates the .zip for the object
    # @param stacks_base_url [String] Base URL for the stacks environment
    def download_url(stacks_base_url: "https://stacks.stanford.edu")
      "#{stacks_base_url}/object/#{bare_druid}"
    end

    # The IIIF manifest URL for the object, version 3 by default
    # PURL generates the IIIF manifest
    # @param purl_base_url [String] Base URL for the PURL environment
    # @param version [Integer] The IIIF version to use (3 or 2)
    def iiif_manifest_url(purl_base_url: "https://purl.stanford.edu", version: 3)
      "#{purl_url(purl_base_url:)}/#{(version == 3) ? "iiif3" : "iiif"}/manifest"
    end

    # List of titles for the object
    def titles(type: :main)
      titles = cocina_doc.dig("description", "title").map { |title| Cocina::Models::Title.new(title) }
      case type
      when :main
        Cocina::Models::Builders::TitleBuilder.main_title(titles)
      when :full
        Cocina::Models::Builders::TitleBuilder.full_title(titles)
      when :additional
        Cocina::Models::Builders::TitleBuilder.additional_titles(titles)
      else
        raise ArgumentError, "Invalid title type: #{type}"
      end
    end
  end
end
