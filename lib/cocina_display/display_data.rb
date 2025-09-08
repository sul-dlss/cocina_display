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

      # Create display data from a string value.
      # @param value [String] The string value to display
      # @param label [String] The label for the display data
      # @return [Array<DisplayData>] The display data
      def from_string(value, label: nil)
        from_objects([DescriptiveValue.new(label: label, value: value)])
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
    # @param objects [Array<Object>]
    def initialize(label:, objects:)
      @label = label
      @objects = objects
    end

    attr_reader :label

    # @return [Array<String>] The unique, non-blank values for display
    def values
      values_split_on_newlines.compact_blank.uniq
    end

    private

    # @return [Array<String>] The flattened array of split strings
    def values_split_on_newlines
      @objects.map(&:to_s).flat_map { |value| value&.gsub("&#10;", "\n")&.split("\n")&.map(&:strip) }
    end
  end
end
