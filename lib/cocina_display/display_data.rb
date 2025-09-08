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
        from_objects(descriptive_values_from_string(value, label: label))
      end

      # Create an array containing a descriptive object from a string value.
      # Can be used to combine a string derived value with other metadata objects.
      # @param string [String] The string value to display
      # @param label [String] The label for the display data
      # @return [Array<DescriptiveValue>] The descriptive values
      def descriptive_values_from_string(string, label: nil)
        [DescriptiveValue.new(label: label, value: string)]
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

    # A Data object to hold link text and URL for link metadata.
    # @attr [String] link_text
    # @attr [String] url
    LinkData = Data.define(:link_text, :url)

    # The unique, non-blank values for display
    # @return [Array<String>]
    def values
      values_for_display.compact_blank.uniq
    end

    private

    # Extract the values for display from the objects.
    # @return [Array<String|LinkData>]
    def values_for_display
      @objects.flat_map do |object|
        if object.respond_to?(:link_text) || url?(object.to_s)
          convert_url_strings_to_link_data(object)
        else
          split_string_on_newlines(object.to_s)
        end
      end
    end

    # Convert a URL string or object with link text to a LinkData object.
    # @param object [Object] The object to convert
    # @return [LinkData]
    def convert_url_strings_to_link_data(object)
      LinkData.new(link_text: (object.respond_to?(:link_text) ? object.link_text : nil), url: object.to_s)
    end

    # Split a string on newlines (including HTML-encoded newlines) and strip whitespace.
    # @param string [String] The string to split
    # @return [Array<String>]
    def split_string_on_newlines(string)
      string&.gsub("&#10;", "\n")&.split("\n")&.map(&:strip)
    end

    # Whether a string looks like a URL.
    # @param string [String] The string to check
    # @return [Boolean]
    def url?(string)
      string&.match?(URI::DEFAULT_PARSER.make_regexp(["http", "https"]))
    end
  end
end
