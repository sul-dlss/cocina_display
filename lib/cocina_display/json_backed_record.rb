# frozen_string_literal: true

module CocinaDisplay
  class JsonBackedRecord
    # The parsed Cocina document.
    # @return [Hash]
    attr_reader :cocina_doc

    # Initialize a CocinaRecord with a Cocina document hash.
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
  end
end
