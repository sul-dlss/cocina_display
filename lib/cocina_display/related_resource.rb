# frozen_string_literal: true

module CocinaDisplay
  # A resource related to the record. See https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/models/related_resource.rb
  # @note Related resources have no structural metadata.
  class RelatedResource < JsonBackedRecord
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

    # Label used to group the related resource for display.
    # @return [String]
    def label
      cocina_doc.dig("description", "displayLabel").presence || type_label
    end

    # String representation of the related resource.
    # @return [String, nil]
    def to_s
      display_data.flat_map(&:values).first
    end

    # URL to the related resource for link construction.
    # If there are multiple URLs, uses the first.
    # @return [String, nil]
    def url
      (urls.map(&:to_s) + identifiers.map(&:uri) + [purl_url]).compact.first
    end

    # Is this a related resource with a URL?
    # @return [Boolean]
    def url?
      url.present?
    end

    # Nested display data for the related resource.
    # Combines titles, contributors, notes, and access information.
    # @note Used for extended display of citations, e.g. on hp566jq8781.
    # @return [Array<DisplayData>]
    def display_data
      title_display_data + contributor_display_data + general_note_display_data + preferred_citation_display_data + access_display_data + identifier_display_data
    end

    private

    # Key used for i18n lookup of the label, based on the type.
    # Falls back to a generic label for any unknown types.
    # @return [String]
    def type_label
      I18n.t(type&.parameterize&.underscore, default: :related_to, scope: "cocina_display.field_label.related_resource")
    end
  end
end
