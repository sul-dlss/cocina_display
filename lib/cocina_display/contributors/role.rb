# frozen_string_literal: true

require_relative "../vocabularies/marc_relator_codes"

module CocinaDisplay
  module Contributors
    # A role associated with a contributor.
    class Role
      attr_reader :cocina

      # Initialize a Role object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the role.
      def initialize(cocina)
        @cocina = cocina
      end

      # The name of the role.
      # Translates the MARC relator code if no value was present.
      # @return [String, nil]
      def to_s
        cocina["value"] || (Vocabularies::MARC_RELATOR[code] if marc_relator?)
      end

      # A code associated with the role, e.g. a MARC relator code.
      # @return [String, nil]
      def code
        cocina["code"]
      end

      # Does this role indicate the contributor is an author?
      # @return [Boolean]
      def author?
        to_s.match?(/^(author|creator|primary investigator)/i)
      end

      # Does this role indicate the contributor is a publisher?
      # @return [Boolean]
      def publisher?
        to_s.match?(/^publisher/i)
      end

      # Does this role indicate the contributor is a funder?
      # @return [Boolean]
      def funder?
        to_s.match?(/^funder/i)
      end

      private

      # Does this role have a MARC relator code?
      # @return [Boolean]
      def marc_relator?
        cocina.dig("source", "code") == "marcrelator"
      end
    end
  end
end
