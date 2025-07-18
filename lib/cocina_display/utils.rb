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
        result << if value.end_with?(delimiter.strip)
          value + " "
        else
          value + delimiter
        end
      end.delete_suffix(delimiter)
    end

    # Recursively flatten structured, parallel, and grouped values in Cocina metadata.
    # Returns a list of hashes representing the "leaf" nodes with +value+ key.
    # @return [Array<Hash>] List of node hashes with "value" present
    # @param cocina [Hash] The Cocina structured data to flatten
    # @param output [Array] Used for recursion, should be empty on first call
    # @example simple value
    #  cocina = { "value" => "John Doe", "type" => "name" }
    #  Utils.flatten_nested_values(cocina)
    #  #=> [{"value" => "John Doe", "type" => "name"}]
    # @example structured values
    #  cocina = { "structuredValue" => [{"value" => "foo"},  {"value" => "bar"}] }
    #  Utils.flatten_nested_values(cocina)
    #  #=> [{"value" => "foo"}, {"value" => "bar"}]
    # @example parallel structured and simple values
    #  cocina = { "parallelValue" => [{"value" => "foo" }, { "structuredValue" => [{"value" => "bar"},  {"value" => "baz"}] }] }
    #  Utils.flatten_nested_values(cocina)
    #  #=> [{"value" => "foo"}, {"value" => "foo"}, {"value" => "baz"}]
    def self.flatten_nested_values(cocina, output = [])
      return [cocina] if cocina["value"].present?
      return cocina.flat_map { |node| flatten_nested_values(node, output) } if cocina.is_a?(Array)

      nested_values = Array(cocina["structuredValue"]) + Array(cocina["parallelValue"]) + Array(cocina["groupedValue"])
      return output unless nested_values.any?

      nested_values.flat_map { |node| flatten_nested_values(node, output) }
    end

    # Recursively remove empty values from a hash, including nested hashes and arrays.
    # @param hash [Hash] The hash to process
    # @param output [Hash] Used for recursion, should be empty on first call
    # @return [Hash] The hash with empty values removed
    # @example
    #  hash = { "name" => "", "age" => nil, "address => { "city" => "Anytown", "state" => [] } }
    #  #  Utils.remove_empty_values(hash)
    #  #=> { "address" => { "city" => "Anytown" } }
    def self.deep_compact_blank(hash, output = {})
      hash.each do |key, value|
        if value.is_a?(Hash)
          nested = deep_compact_blank(value)
          output[key] = nested unless nested.empty?
        elsif value.is_a?(Array)
          compacted_array = value.map { |v| deep_compact_blank(v) }.reject(&:blank?)
          output[key] = compacted_array unless compacted_array.empty?
        elsif value.present?
          output[key] = value
        end
      end
      output
    end
  end
end
