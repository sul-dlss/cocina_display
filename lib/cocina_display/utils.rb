require "active_support/core_ext/object/blank"

module CocinaDisplay
  # Helper methods for string formatting, etc.
  module Utils
    # Join non-empty values into a string using provided delimiter.
    # If values already end in delimiter (ignoring whitespace), join with a space instead.
    # @param values [Array<String>] The values to compact and join
    # @param delimiter [String] The delimiter to use for joining, default is space
    # @return [String] The compacted and joined string
    def self.compact_and_join(values, delimiter: " ")
      compacted_values = values.compact_blank.map(&:strip)
      return compacted_values.first if compacted_values.one?

      compacted_values.reduce(+"") do |result, value|
        result << if value.end_with?(delimiter.strip) || value.start_with?(delimiter.strip)
          value + " "
        else
          value + delimiter
        end
      end.delete_prefix(delimiter).delete_suffix(delimiter).strip
    end

    # Recursively flatten structured, and grouped values in Cocina metadata.
    # Returns a list of hashes representing the "leaf" nodes with +value+ key.
    # @return [Array<Hash>] List of node hashes with "value" present
    # @param cocina [Hash] The Cocina structured data to flatten
    # @param output [Array] Used for recursion, should be empty on first call
    # @param atomic_types [Array<String>] Types considered atomic; will not be flattened
    # @example simple value
    #  cocina = { "value" => "John Doe", "type" => "name" }
    #  Utils.flatten_nested_values(cocina)
    #  #=> [{"value" => "John Doe", "type" => "name"}]
    # @example structured values
    #  cocina = { "structuredValue" => [{"value" => "foo"},  {"value" => "bar"}] }
    #  Utils.flatten_nested_values(cocina)
    #  #=> [{"value" => "foo"}, {"value" => "bar"}]
    # @example nested structured and simple values
    #  cocina = { "structuredValue" => [{"value" => "foo" }, { "structuredValue" => [{"value" => "bar"},  {"value" => "baz"}] }] }
    #  Utils.flatten_nested_values(cocina)
    #  #=> [{"value" => "foo"}, {"value" => "foo"}, {"value" => "baz"}]
    def self.flatten_nested_values(cocina, output = [], atomic_types: [])
      return [cocina] if cocina["value"].present?
      return [cocina] if atomic_types.include?(cocina["type"])
      return cocina.flat_map { |node| flatten_nested_values(node, output, atomic_types: atomic_types) } if cocina.is_a?(Array)

      nested_values = Array(cocina["structuredValue"]) + Array(cocina["groupedValue"])
      return output unless nested_values.any?

      nested_values.flat_map { |node| flatten_nested_values(node, output, atomic_types: atomic_types) }
    end

    # Recursively remove empty values from a hash, including nested hashes and arrays.
    # @param [Hash, String, NilClass] node The object to process
    # @param [Array<String>] preserve_keys Keys that should be kept even if their value is blank
    # @return [Hash, String] The hash with empty values removed, string if the node you pass in is a string
    # @example
    #  hash = { "name" => "", "age" => nil, "address => { "city" => "Anytown", "state" => [] } }
    #  #  Utils.remove_empty_values(hash)
    #  #=> { "address" => { "city" => "Anytown" } }
    def self.deep_compact_blank(node, preserve_keys: [])
      return node unless node.is_a?(Hash)

      preserve_keys = preserve_keys.map(&:to_s)

      node.each_with_object({}) do |(key, value), output|
        preserve_key = preserve_keys.include?(key.to_s)

        case value
        when Hash
          nested = deep_compact_blank(value, preserve_keys: preserve_keys)
          output[key] = nested if !nested.empty? || preserve_key
        when Array
          compacted_array = value.map { |v| deep_compact_blank(v, preserve_keys: preserve_keys) }.compact_blank
          output[key] = compacted_array if !compacted_array.empty? || preserve_key
        when TrueClass, FalseClass
          output[key] = value
        else
          output[key] = value if value.present? || preserve_key
        end
      end
    end
  end
end
