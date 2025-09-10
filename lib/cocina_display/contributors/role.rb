# frozen_string_literal: true

module CocinaDisplay
  module Contributors
    # A role associated with a contributor.
    class Role
      attr_reader :cocina
      DEFAULT_ROLE = I18n.t("cocina_display.contributors.role.default_value")

      # Initialize a Role object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the role.
      def initialize(cocina)
        @cocina = cocina
      end

      def self.create_roles(roles)
        Array(roles.presence || [{"value" => DEFAULT_ROLE}]).map { |role| new(role) }
      end

      # The name of the role.
      # Translates the MARC relator code if no value was present.
      # Otherwise returns the default role.
      # @return [String]
      def to_s
        @to_s ||= cocina["value"] || (Vocabularies::MARC_RELATOR[code] if marc_relator?) || DEFAULT_ROLE
      end

      def blank?
        to_s == DEFAULT_ROLE
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
