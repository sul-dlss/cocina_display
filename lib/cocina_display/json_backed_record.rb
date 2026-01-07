# frozen_string_literal: true

module CocinaDisplay
  # Superclass for metadata records backed by a Cocina JSON document.
  class JsonBackedRecord
    # The parsed Cocina document.
    # @return [Hash]
    attr_reader :cocina_doc

    # Initialize a record with a Cocina document hash.
    # @param cocina_doc [Hash]
    def initialize(cocina_doc)
      @cocina_doc = cocina_doc
    end

    # Evaluate a JSONPath expression against the Cocina document.
    # @return [Enumerator] An enumerator that yields results matching the expression.
    # @param path_expression [String] The JSONPath expression to evaluate.
    # @see https://www.rubydoc.info/gems/janeway-jsonpath/0.6.0/file/README.md
    # @example Name values for contributors
    #  record.path("$.description.contributor.*.name.*.value").search #=> ["Smith, John", "ACME Corp."]
    # @example Filtering nodes using a condition
    #  record.path("$.description.contributor[?(@.type == 'person')].name.*.value").search #=> ["Smith, John"]
    def path(path_expression)
      Janeway.enum_for(path_expression, cocina_doc)
    end

    # Flattened, normalized aggregation of all node texts in the Cocina document.
    # @note Used for 'all search' fields in indexing.
    # @return [String]
    def text
      node_texts.compact.join(" ").gsub(/\s+/, " ").strip
    end

    private

    # Array of all node values/codes except those under "source" keys.
    # Used to build flattened text representation.
    # @note Source values are omitted because they usually indicate ontologies/vocabularies.
    # @return [Array<String>]
    def node_texts
      path("$..['code', 'value']").map { |node, _p, _i, path| node unless path.to_s.include?("['source']") }
    end
  end
end
