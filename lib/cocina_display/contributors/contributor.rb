# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/array/conversions"

require_relative "../utils"
require_relative "name"
require_relative "role"

module CocinaDisplay
  module Contributors
    # A contributor to a work, such as an author or publisher.
    class Contributor
      attr_reader :cocina

      # Initialize a Contributor object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the contributor.
      def initialize(cocina)
        @cocina = cocina
      end

      # String representation of the contributor, including name and role.
      # Used for debugging and logging.
      # @return [String]
      def to_s
        Utils.compact_and_join([display_name, display_role], delimiter: ": ")
      end

      # Is this contributor a human?
      # @return [Boolean]
      def person?
        cocina["type"] == "person"
      end

      # Is this contributor an organization?
      # @return [Boolean]
      def organization?
        cocina["type"] == "organization"
      end

      # Is this contributor a conference?
      # @return [Boolean]
      def conference?
        cocina["type"] == "conference"
      end

      # Is this contributor marked as primary?
      # @return [Boolean]
      def primary?
        cocina["status"] == "primary"
      end

      # Does this contributor have a role that indicates they are an author?
      # @return [Boolean]
      def author?
        roles.any?(&:author?)
      end

      # Does this contributor have a role that indicates they are a publisher?
      # @return [Boolean]
      def publisher?
        roles.any?(&:publisher?)
      end

      # Does this contributor have a role that indicates they are a funder?
      # @return [Boolean]
      def funder?
        roles.any?(&:funder?)
      end

      # Does this contributor have any roles defined?
      # @return [Boolean]
      def role?
        roles.any?
      end

      # The display name for the contributor as a string.
      # Uses the first name if multiple names are present.
      # @param with_date [Boolean] Include life dates, if present
      # @return [String]
      def display_name(with_date: false)
        names.map { |name| name.to_s(with_date: with_date) }.first
      end

      # The full forename for the contributor from the first available name.
      # @see Contributor::Name::forename_str
      # @return [String, nil]
      def forename
        names.map(&:forename_str).first.presence
      end

      # The full surname for the contributor from the first available name.
      # @see Contributor::Name::surname_str
      # @return [String, nil]
      def surname
        names.map(&:surname_str).first.presence
      end

      # A string representation of the contributor's roles, formatted for display.
      # If there are multiple roles, they are joined with commas.
      # @return [String]
      def display_role
        roles.map(&:to_s).to_sentence
      end

      # All names in the Cocina as Name objects.
      # @return [Array<Name>]
      def names
        @names ||= Array(cocina["name"]).map { |name| Name.new(name) }
      end

      # All roles in the Cocina structured data.
      # @return [Array<Hash>]
      def roles
        @roles ||= Array(cocina["role"]).map { |role| Role.new(role) }
      end
    end
  end
end
