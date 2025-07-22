# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/array/conversions"

require_relative "utils"
require_relative "marc_relator_codes"

module CocinaDisplay
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
      names.map { |name| name.display_str(with_date: with_date) }.first
    end

    # A string representation of the contributor's roles, formatted for display.
    # If there are multiple roles, they are joined with commas.
    # @return [String]
    def display_role
      roles.map(&:display_str).to_sentence
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

    # A name associated with a contributor.
    class Name
      attr_reader :cocina

      # Initialize a Name object with Cocina structured data.
      # @param cocina [Hash] The Cocina structured data for the name.
      def initialize(cocina)
        @cocina = cocina
      end

      # The display string for the name, optionally including life dates.
      # Uses these values in order, if present:
      # 1. Unstructured value
      # 2. Any structured/parallel values marked as "display"
      # 3. Joined structured values, optionally with life dates
      # @param with_date [Boolean] Include life dates, if present
      # @return [String]
      # @example no dates
      #   name.display_name # => "King, Martin Luther, Jr."
      # @example with dates
      #   name.display_name(with_date: true) # => "King, Martin Luther, Jr., 1929-1968"
      def display_str(with_date: false)
        if cocina["value"].present?
          cocina["value"]
        elsif display_name_str.present?
          display_name_str
        elsif dates_str.present? && with_date
          Utils.compact_and_join([full_name_str, dates_str], delimiter: ", ")
        else
          full_name_str
        end
      end

      private

      # The full name as a string, combining all name components.
      # @return [String]
      def full_name_str
        Utils.compact_and_join(name_components, delimiter: ", ")
      end

      # Flattened form of any names explicitly marked as "display name".
      # @return [String]
      def display_name_str
        Utils.compact_and_join(Array(name_values["display"]), delimiter: ", ")
      end

      # List of all name components.
      # If any of forename, surname, or term of address are present, those are used.
      # Otherwise, fall back to any names explicitly marked as "name" or untyped.
      # @return [Array<String>]
      def name_components
        [surname_str, forename_ordinal_str, terms_of_address_str].compact_blank.presence || Array(name_values["name"])
      end

      # Flatten all forenames and ordinals into a single string.
      # @return [String]
      def forename_ordinal_str
        Utils.compact_and_join(Array(name_values["forename"]) + Array(name_values["ordinal"]), delimiter: " ")
      end

      # Flatten all terms of address into a single string.
      # @return [String]
      def terms_of_address_str
        Utils.compact_and_join(Array(name_values["term of address"]), delimiter: ", ")
      end

      # Flatten all surnames into a single string.
      # @return [String]
      def surname_str
        Utils.compact_and_join(Array(name_values["surname"]), delimiter: " ")
      end

      # Flatten all life and activity dates into a single string.
      # @return [String]
      def dates_str
        Utils.compact_and_join(Array(name_values["life dates"]) + Array(name_values["activity dates"]), delimiter: ", ")
      end

      # A hash mapping destructured name types to their values.
      # Name values with no type are grouped under "name".
      # @return [Hash<String, Array<String>>]
      # @see https://github.com/sul-dlss/cocina-models/blob/main/docs/description_types.md#contributor-name-part-types-for-structured-value
      # @note Currently we do nothing with "alternative", "inverted full name", "pseudonym", and "transliteration" types.
      def name_values
        Utils.flatten_nested_values(cocina).each_with_object({}) do |node, hash|
          type = node["type"] || "name"
          hash[type] ||= []
          hash[type] << node["value"]
        end.compact_blank
      end
    end

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
      def display_str
        cocina["value"] || (MARC_RELATOR[code] if marc_relator?)
      end

      # A code associated with the role, e.g. a MARC relator code.
      # @return [String, nil]
      def code
        cocina["code"]
      end

      # Does this role indicate the contributor is an author?
      # @return [Boolean]
      def author?
        display_str =~ /^(author|creator)/i
      end

      # Does this role indicate the contributor is a publisher?
      # @return [Boolean]
      def publisher?
        display_str =~ /^publisher/i
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
