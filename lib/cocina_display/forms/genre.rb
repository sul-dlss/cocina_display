module CocinaDisplay
  module Forms
    # A Genre form associated with part or all of a Cocina object.
    class Genre < Form
      # Genres are capitalized for display.
      # @return [String]
      def to_s
        super&.upcase_first
      end
    end
  end
end
