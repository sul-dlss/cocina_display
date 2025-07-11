require_relative "../subject"

module CocinaDisplay
  module Concerns
    # Methods for extracting and formatting subject information.
    module Subjects
      # All unique subjects that are topics, formatted as strings for display.
      # @return [Array<String>]
      def subject_topics
        subjects.filter { |s| s.type == "topic" }.map(&:display_str).uniq
      end

      # All unique subjects that are genres, formatted as strings for display.
      # @return [Array<String>]
      def subject_genres
        subjects.filter { |s| s.type == "genre" }.map(&:display_str).uniq
      end

      # All unique subjects that are titles, formatted as strings for display.
      # @return [Array<String>]
      def subject_titles
        subjects.filter { |s| s.type == "title" }.map(&:display_str).uniq
      end

      # All unique subjects that are date/time info, formatted as strings for display.
      # @return [Array<String>]
      def subject_temporal
        subjects.filter { |s| s.type == "time" }.map(&:display_str).uniq
      end

      # All unique subjects that are occupations, formatted as strings for display.
      # @return [Array<String>]
      def subject_occupations
        subjects.filter { |s| s.type == "occupation" }.map(&:display_str).uniq
      end

      # All unique subjects that are names of entities, formatted as strings for display.
      # @note Multiple types are handled: person, family, organization, conference, etc.
      # @see CocinaDisplay::NameSubject
      # @return [Array<String>]
      def subject_names
        subjects.filter { |s| s.is_a? NameSubject }.map(&:display_str).uniq
      end

      # Combination of all subject values for faceting.
      # @see #subject_facet
      # @see #subject_temporal_genre_facet
      # @return [Array<String>]
      def subject_all_facet
        subject_facet + subject_temporal_genre_facet
      end

      # Combination of topic, occupation, name, and title subject values for faceting.
      # @see #subject_topics
      # @see #subject_other_facet
      # @return [Array<String>]
      def subject_facet
        subject_topics + subject_other_facet
      end

      # Combination of occupation, name, and title subject values for faceting.
      # @see #subject_occupations
      # @see #subject_names
      # @see #subject_titles
      # @return [Array<String>]
      def subject_other_facet
        subject_occupations + subject_names + subject_titles
      end

      # Combination of temporal and genre subject values for faceting.
      # @see #subject_temporal
      # @see #subject_genres
      # @return [Array<String>]
      def subject_temporal_genre_facet
        subject_temporal + subject_genres
      end

      private

      # All subjects, accessible as Subject objects.
      # Checks both description.subject and description.geographic.subject.
      # @return [Array<Subject>]
      def subjects
        @subjects ||= Enumerator::Chain.new(
          path("$.description.subject[*]"),
          path("$.description.geographic[*].subject[*]")
        ).map { |s| Subject.from_cocina(s) }
      end
    end
  end
end
