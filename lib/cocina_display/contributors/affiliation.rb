# frozen_string_literal: true

module CocinaDisplay
  module Contributors
    # An affiliation associated with a contributor.
    class Affiliation
      attr_reader :cocina

      # Initialize an Affiliation from Cocina structured data.
      # @param cocina [Hash]
      def initialize(cocina)
        @cocina = cocina
      end

      # String representation of the affiliation, using display name.
      # @return [String, nil]
      def to_s
        display_name
      end

      # The name of the institution or organization.
      # @return [String, nil]
      # @example "Stanford University, Department of Special Collections"
      def display_name
        name_components.join(", ") if name_components.any?
      end

      # Does this Affiliation have a ROR ID?
      # @return [Boolean]
      def ror?
        ror_identifier.present?
      end

      # ROR URI for the Affiliation, if present.
      # @return [String, nil]
      # @example https://ror.org/00f54p054
      def ror
        ror_identifier&.uri
      end

      # ROR ID for the Affiliation, if present.
      # @return [String, nil]
      # @example 00f54p054
      def ror_id
        ror_identifier&.identifier
      end

      # Identifiers associated with the Affiliation.
      # @return [Array<CocinaDisplay::Identifier>]
      def identifiers
        @identifiers ||= Utils.flatten_nested_values(cocina)
          .pluck("identifier").flatten.compact_blank.map { |id| CocinaDisplay::Identifier.new(id) }
      end

      # All components of the Affiliation name as an array of strings.
      # @return [Array<String>]
      # @example ["Stanford University", "Department of Special Collections"]
      def name_components
        @name_components ||= Utils.flatten_nested_values(cocina).pluck("value").compact_blank
      end

      # The first Identifier object that contains a ROR ID.
      # @note This will usually be the most general ROR ID, if multiple.
      # @return [CocinaDisplay::Identifier, nil]
      def ror_identifier
        identifiers.find { |id| id.type == "ROR" }
      end
    end
  end
end
