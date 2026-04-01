# frozen_string_literal: true

module CocinaDisplay
  module Contributors
    # A name associated with a contributor, potentially in multiple languages.
    class Name < Parallel::Parallel
      # The name is represented by the main parallel value.
      delegate :to_s, :forename_str, :surname_str, to: :main_value

      private

      # The class to use for parallel values.
      # @return [Class]
      def parallel_value_class
        NameValue
      end
    end
  end
end
