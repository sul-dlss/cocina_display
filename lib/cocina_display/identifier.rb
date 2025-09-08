module CocinaDisplay
  # An identifier for an object or a descriptive value.
  class Identifier
    attr_reader :cocina

    # Source URI values for common identifiers
    # If you have the bare ID, you can always add it to these to make a valid URL
    SOURCE_URIS = {
      "ORCID" => "https://orcid.org/",
      "ROR" => "https://ror.org/",
      "DOI" => "https://doi.org/",
      "ISNI" => "https://isni.org/"
    }.freeze

    # Initialize an Identifier from Cocina structured data.
    # @param cocina [Hash]
    def initialize(cocina)
      @cocina = cocina
    end

    # String representation of the identifier.
    # Prefers the URI representation where present.
    # @return [String]
    def to_s
      uri || structured_identifier
    end

    # The raw value from the Cocina structured data.
    # Prefers the URI representation where present.
    # @return [String, nil]
    def value
      cocina["uri"].presence || cocina["value"].presence
    end

    # The "identifying" part of the identifier.
    # Tries to parse from the end of the URI.
    # @example DOI
    #   10.1234/doi
    # @return [String, nil]
    def identifier
      URI(value).path.delete_prefix("/") if value
    end

    def structured_identifier
      return value unless code && code != "local"

      "#{code}: #{value}"
    end

    # The identifier as a URI, if available.
    # Tries to construct a URI if the parts are available to do so.
    # @example DOI
    #   https://doi.org/10.1234/doi
    # @return [String, nil]
    def uri
      cocina["uri"].presence || ([scheme_uri, identifier].join if scheme_uri && identifier)
    end

    # The type of the identifier, e.g. "DOI".
    # @return [String, nil]
    def type
      ("DOI" if doi?) || cocina["type"].presence
    end

    # The declared encoding of the identifier, if any.
    # @return [String, nil]
    def code
      cocina.dig("source", "code").presence
    end

    # The base URI used to resolve the identifier, if any.
    # @example DOI
    #  https://doi.org/
    # @return [String, nil]
    def scheme_uri
      cocina.dig("source", "uri") || SOURCE_URIS[type]
    end

    # Label used to render the identifier for display.
    # Uses a displayLabel if available, otherwise tries to look up via type.
    # Falls back to a generic label for any unknown identifier types.
    # @return [String]
    def label
      cocina["displayLabel"].presence ||
        I18n.t(label_key, default: :identifier, scope: "cocina_display.field_label.identifier")
    end

    # Check if the identifier is a DOI.
    # There are several indicators that could suggest this.
    # @return [Boolean]
    def doi?
      cocina["type"]&.match?(/doi/i) || code == "doi" || cocina["uri"]&.include?("://doi.org")
    end

    private

    # Key used for i18n lookup of the label, based on the type.
    # @return [String, nil]
    def label_key
      type&.parameterize&.underscore
    end
  end
end
