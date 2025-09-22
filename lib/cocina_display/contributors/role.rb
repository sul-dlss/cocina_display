# frozen_string_literal: true

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
      # @return [String, nil] A nil role is typically displayed in the UI as an "Associated with" relationship
      def to_s
        cocina.fetch("value") { marc_value }
      end

      # Does this role indicate the contributor is an author?
      # @return [Boolean]
      def author?
        /^(author|creator|primary investigator)/i.match? to_s
      end

      # Does this role indicate the contributor is a publisher?
      # @return [Boolean]
      def publisher?
        /^publisher/i.match? to_s
      end

      # Does this role indicate the contributor is a funder?
      # @return [Boolean]
      def funder?
        /^funder/i.match? to_s
      end

      private

      # The name of the MARC relator role
      # @raises [KeyError] if the role is not valid
      # @return [String, nil]
      def marc_value
        return unless marc_relator?

        Vocabularies::MARC_RELATOR.fetch(code)
      end

      # A code associated with the role, e.g. a MARC relator code.
      # @return [String, nil]
      def code
        cocina["code"]
      end

      # Does this role have a MARC relator code?
      # @return [Boolean]
      def marc_relator?
        cocina.dig("source", "code") == "marcrelator"
      end
    end
  end
end
