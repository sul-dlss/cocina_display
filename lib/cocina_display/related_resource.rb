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
    # If not titled, uses a URL or the label as a fallback.
    # @return [String, nil]
    def to_s
      display_title || url || label
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
    # @return [Array<DisplayData>]
    def display_data
      title_display_data(exclude_primary: true) +
        contributor_display_data +
        event_display_data +
        general_note_display_data +
        preferred_citation_display_data +
        access_display_data +
        identifier_display_data
    end

    private

    # Display data for access-related information.
    # Doesn't duplicate the URL used to link the related resource itself, if any.
    # @return [Array<DisplayData>]
    def access_display_data
      objects = accesses + access_contacts + purls + urls
      CocinaDisplay::DisplayData.from_objects(objects.reject { |obj| obj.to_s == url.to_s })
    end

    # Key used for i18n lookup of the label, based on the type.
    # Falls back to a generic label for any unknown types.
    # @return [String]
    def type_label
      I18n.t(type&.parameterize&.underscore, default: :related_to, scope: "cocina_display.field_label.related_resource")
    end
  end
end
