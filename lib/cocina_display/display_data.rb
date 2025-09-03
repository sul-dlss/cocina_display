# frozen_string_literal: true

module CocinaDisplay
  # A data structure to be rendered into HTML by the consumer.
  # @attr [String] label
  # @attr [Array<String | DisplayData>] values
  DisplayData = Data.define(:label, :values) do
    # Parse a Cocina object into a DisplayData instance.
    # Uses the displayLabel, if one is present.
    # @param cocina [Hash]
    def self.from_cocina(cocina)
      new(label: cocina["displayLabel"], values: Array(cocina["value"]))
    end
  end
end
