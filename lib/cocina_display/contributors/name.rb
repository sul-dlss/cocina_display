# frozen_string_literal: true

module CocinaDisplay
  module Contributors
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
      #   name.to_s # => "King, Martin Luther, Jr."
      # @example with dates
      #   name.to_s(with_date: true) # => "King, Martin Luther, Jr., 1929-1968"
      def to_s(with_date: false)
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

      # The full name as a string, combining all name components and terms of address.
      # @return [String]
      def full_name_str
        Utils.compact_and_join(name_components.push(terms_of_address_str), delimiter: ", ")
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
        [surname_str, forename_str].compact_blank.presence || Array(name_values["name"])
      end

      # Flatten all terms of address into a comma-delimited string.
      # @return [String]
      def terms_of_address_str
        Utils.compact_and_join(Array(name_values["term of address"]), delimiter: ", ")
      end

      # Flatten all forename values and ordinals into a whitespace-delimited string.
      # @return [String]
      def forename_str
        Utils.compact_and_join(Array(name_values["forename"]) + Array(name_values["ordinal"]), delimiter: " ")
      end

      # Flatten all surname values into a whitespace-delimited string.
      # @return [String]
      def surname_str
        Utils.compact_and_join(Array(name_values["surname"]), delimiter: " ")
      end

      # Flatten all life and activity dates into a comma-delimited string.
      # @return [String]
      def dates_str
        Utils.compact_and_join(Array(name_values["life dates"]) + Array(name_values["activity dates"]), delimiter: ", ")
      end

      private

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
  end
end
