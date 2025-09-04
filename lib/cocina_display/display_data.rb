# frozen_string_literal: true

module CocinaDisplay
  # A data structure to be rendered into HTML by the consumer.
  # @attr [String] label
  # @attr [Array<String | DisplayData>] values
  DisplayData = Data.define(:label, :values)
end
