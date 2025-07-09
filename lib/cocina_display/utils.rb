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

    # Recursively flatten structured values in Cocina metadata.
    # Returns a list of hashes representing the "leaf" nodes with values.
    # @return [Array<Hash>] List of node hashes with "value" present
    def self.flatten_structured_values(cocina, output = [])
      return [cocina] if cocina["value"].present?
      return cocina.flat_map { |node| flatten_structured_values(node, output) } if cocina.is_a?(Array)
      return output unless (structured_values = Array(cocina["structuredValue"])).present?

      structured_values.flat_map { |node| flatten_structured_values(node, output) }
    end
  end
end
