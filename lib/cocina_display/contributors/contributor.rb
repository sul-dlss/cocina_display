# frozen_string_literal: true

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

      # String representation of the contributor, using display name with date.
      # @return [String, nil]
      def to_s
        display_name(with_date: true)
      end

      # Support equality based on the underlying Cocina data.
      # @param other [Object]
      def ==(other)
        other.is_a?(Contributor) && other.cocina == cocina
      end

      # Identifiers for the contributor.
      # @return [Array<Identifier>]
      def identifiers
        Array(cocina["identifier"]).map { |id| Identifier.new(id) }
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

      # The primary display name for the contributor as a string.
      # @param with_date [Boolean] Include life dates, if present
      # @return [String, nil]
      def display_name(with_date: false)
        primary_name&.to_s(with_date: with_date)
      end

      # String renderings of all names for the contributor.
      # @param with_date [Boolean] Include life dates, if present
      # @return [Array<String>]
      def display_names(with_date: false)
        names.map { |name| name.to_s(with_date: with_date) }.compact_blank
      end

      # A single primary name for the contributor.
      # Prefers a name of type "display" or one marked primary.
      # @return [Contributor::Name, nil]
      def primary_name
        names.find { |name| name.type == "display" }.presence ||
          names.find(&:primary?).presence ||
          names.first
      end

      # The forename for the contributor, if structured name info is available.
      # @see Contributor::Name::forename_str
      # @return [String, nil]
      def forename
        names.map(&:forename_str).first.presence
      end

      # The surname for the contributor, if structured name info is available.
      # @see Contributor::Name::surname_str
      # @return [String, nil]
      def surname
        names.map(&:surname_str).first.presence
      end

      # All names in the Cocina as Name objects.
      # Flattens parallel values into separate Name objects.
      # @return [Array<Name>]
      def names
        @names ||= Array(cocina["name"]).flat_map do |name|
          (Array(name["parallelValue"]).presence || [name]).filter_map do |name_value|
            unless name_value.blank?
              Name.new(name_value).tap do |name_obj|
                name_obj.type ||= name["type"]
                name_obj.status ||= name["status"]
              end
            end
          end
        end
      end

      # All roles in the Cocina structured data.
      # @return [Array<Hash>]
      def roles
        @roles ||= Array(cocina["role"]).map { |role| Role.new(role) }
      end
    end
  end
end
