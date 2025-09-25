# frozen_string_literal: true

module CocinaDisplay
  # A data structure to be rendered into HTML by the consumer.
  class DisplayData
    class << self
      # Given objects that support #to_s and #label, group them into {DisplayData}.
      # Groups by each object's +label+ and keeps unique, non-blank values.
      # @param objects [Array<Object>]
      # @return [Array<DisplayData>]
      def from_objects(objects)
        objects.group_by(&:label)
          .map { |label, objs| new(label: label, objects: objs) }
          .reject { |data| data.values.empty? }
      end

      # Given an array of Cocina hashes, group them into {DisplayData}.
      # Uses +label+ as the label if provided, but honors +displayLabel+ if set.
      # Keeps the unique, non-blank values under each label.
      # @param cocina [Array<Hash>]
      # @param label [String]
      # @return [Array<DisplayData>]
      def from_cocina(cocina, label: nil)
        from_objects(descriptive_values_from_cocina(cocina, label: label))
      end

      # Create display data from string values.
      # @param value [String] The string values to display
      # @param label [String] The label for the display data
      # @return [Array<DisplayData>] The display data
      def from_strings(values, label: nil)
        from_objects(descriptive_values_from_strings(values, label: label))
      end

      # Create an array containing a descriptive object from string values.
      # Can be used to combine a string derived value with other metadata objects.
      # @param strings [Array<String>] The string values to display
      # @param label [String] The label for the display data
      # @return [Array<DescriptiveValue>] The descriptive values
      def descriptive_values_from_strings(strings, label: nil)
        strings.map { |string| DescriptiveValue.new(label: label, value: string) }
      end

      # Take one or several DisplayData and merge into a single hash.
      # Keys are labels; values are the merged array of values for that label.
      # @param display_data [DisplayData, Array<DisplayData>]
      # @return [Hash{String => Array<String>}] The merged hash
      def to_hash(display_data)
        Array(display_data).map(&:to_h).reduce(:merge)
      end

      private

      # Wrap Cocina nodes into {DescriptiveValue} so they are labelled.
      # Uses +displayLabel+ from the node if present, otherwise uses the provided label.
      # @param cocina [Array<Hash>]
      # @param label [String]
      # @return [Array<DescriptiveValue>]
      def descriptive_values_from_cocina(cocina, label: nil)
        cocina.map { |node| DescriptiveValue.new(label: node["displayLabel"] || label, value: node["value"]) }
      end

      # Wrapper to make Cocina descriptive values respond to #to_s and #label.
      # @attr [String] label
      # @attr [String] value
      DescriptiveValue = Data.define(:label, :value) do
        def to_s
          value
        end
      end
    end

    # Create a DisplayData object from a list of objects that share a label
    # @param label [String]
    # @param objects [Array<#to_s>]
    def initialize(label:, objects:)
      @label = label
      @objects = objects
    end

    attr_reader :label, :objects

    # The unique, non-blank values for display
    # @return [Array<String>]
    def values
      objects.flat_map { |object| split_string_on_newlines(object.to_s) }.compact_blank.uniq
    end

    # Express the display data as a hash mapping the label to its values.
    # @return [Hash{String => Array<String>}] The label and values
    def to_h
      {label => values}
    end

    private

    # Split a string on newlines (including HTML-encoded newlines) and strip whitespace.
    # @param string [String] The string to split
    # @return [Array<String>]
    def split_string_on_newlines(string)
      string&.gsub("&#10;", "\n")&.split("\n")&.map(&:strip)
    end
  end
end
