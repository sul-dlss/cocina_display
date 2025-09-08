module CocinaDisplay
  module Concerns
    # Methods for extracting and formatting subject information.
    module Subjects
      # All unique subject values that are topics.
      # @return [Array<String>]
      def subject_topics
        subject_values.filter { |s| s.type == "topic" }.map(&:to_s).uniq
      end

      # All unique subject values that are genres.
      # @return [Array<String>]
      def subject_genres
        subject_values.filter { |s| s.type == "genre" }.map(&:to_s).uniq
      end

      # All unique subject values that are titles.
      # @return [Array<String>]
      def subject_titles
        subject_values.filter { |s| s.type == "title" }.map(&:to_s).uniq
      end

      # All unique subject values that are date/time info.
      # @return [Array<String>]
      def subject_temporal
        subject_values.filter { |s| s.type == "time" }.map(&:to_s).uniq
      end

      # All unique subject values that are occupations.
      # @return [Array<String>]
      def subject_occupations
        subject_values.filter { |s| s.type == "occupation" }.map(&:to_s).uniq
      end

      # All unique subject values that are named geographic places.
      # @return [Array<String>]
      def subject_places
        place_subject_values.map(&:to_s).uniq
      end

      # All unique subject values that are names of entities.
      # @note Multiple types are handled: person, family, organization, conference, etc.
      # @see CocinaDisplay::NameSubjectValue
      # @return [Array<String>]
      def subject_names
        subject_values.filter { |s| s.is_a? CocinaDisplay::Subjects::NameSubjectValue }.map(&:to_s).uniq
      end

      # Combination of all subject values for searching.
      # @see #subject_topics_other
      # @see #subject_temporal_genre
      # @see #subject_places
      # @return [Array<String>]
      def subject_all
        subject_topics_other + subject_temporal_genre + subject_places
      end

      # Combination of topic, occupation, name, and title subject values for searching.
      # @see #subject_topics
      # @see #subject_other
      # @return [Array<String>]
      def subject_topics_other
        subject_topics + subject_other
      end

      # Combination of occupation, name, and title subject values for searching.
      # @see #subject_occupations
      # @see #subject_names
      # @see #subject_titles
      # @return [Array<String>]
      def subject_other
        subject_occupations + subject_names + subject_titles
      end

      # Combination of temporal and genre subject values for searching.
      # @see #subject_temporal
      # @see #subject_genres
      # @return [Array<String>]
      def subject_temporal_genre
        subject_temporal + subject_genres
      end

      # Combination of all subjects with nested values concatenated for display.
      # @see Subject#to_s
      # @return [Array<String>]
      def subject_all_display
        all_subjects.map(&:to_s).uniq
      end

      # Subject data to be rendered for display.
      # Uses the concatenated form for structured subject values.
      # @see Subject#to_s
      # @return [Array<DisplayData>]
      def subject_display_data
        CocinaDisplay::DisplayData.from_objects(all_subjects - classification_subjects - genre_subjects - coordinate_subjects)
      end

      private

      # All subjects, accessible as {Subject} objects.
      # Checks both description.subject and description.geographic.subject.
      # @return [Array<Subject>]
      def all_subjects
        @all_subjects ||= Enumerator::Chain.new(
          path("$.description.subject[*]"),
          path("$.description.geographic.*.subject[*]")
        ).map { |s| CocinaDisplay::Subjects::Subject.new(s) }
      end

      # {Subject} objects with type "genre".
      # @return [Array<Subject>]
      def genre_subjects
        all_subjects.filter { |subject| subject.type == "genre" }
      end

      # {Subject} objects with type "classification".
      # @return [Array<Subject>]
      def classification_subjects
        all_subjects.filter { |subject| subject.type == "classification" }
      end

      # All subject values, flattened from all subjects.
      # @return [Array<SubjectValue>]
      def subject_values
        @subject_values ||= all_subjects.flat_map(&:subject_values)
      end

      # All subject values that are named places.
      # @return [Array<PlaceSubjectValue>]
      def place_subject_values
        @place_subject_values ||= subject_values.filter { |s| s.is_a? CocinaDisplay::Subjects::PlaceSubjectValue }
      end
    end
  end
end
