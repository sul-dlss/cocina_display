# frozen_string_literal: true

module CocinaDisplay
  # A resource related to the record. See https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/related_resource.rb
  # @note Related resources have no structural metadata.
  class RelatedResource < JsonBackedRecord
    include CocinaDisplay::Concerns::Events
    include CocinaDisplay::Concerns::Contributors
    include CocinaDisplay::Concerns::Identifiers
    include CocinaDisplay::Concerns::Notes
    include CocinaDisplay::Concerns::Titles
    include CocinaDisplay::Concerns::Subjects
    include CocinaDisplay::Concerns::Forms
    include CocinaDisplay::Concerns::Languages
    include CocinaDisplay::Concerns::Geospatial

    # Description of the relation to the source record.
    # @return [String]
    # @example "is part of"
    # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#relatedresource-types
    attr_reader :type

    # Restructure the hash so that everything is under "description" key, since
    # it's all descriptive metadata. This makes most CocinaRecord methods work.
    def initialize(cocina_doc)
      @type = cocina_doc["type"]
      super({"description" => cocina_doc.except("type")})
    end

    # @return [String] the url of the related item
    def url
      cocina_doc.dig("description", "access", "url", 0, "value")
    end

    # @return [String] the purl of the related item
    def purl
      cocina_doc.dig("description", "purl")
    end
  end
end
