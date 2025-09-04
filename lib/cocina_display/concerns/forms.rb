require "active_support/core_ext/enumerable"

module CocinaDisplay
  module Concerns
    # Methods for extracting format/genre information from a Cocina object
    module Forms
      # Resource types of the object, expressed in SearchWorks controlled vocabulary.
      # @return [Array<String>]
      def resource_types
        mapped_values = resource_type_values.flat_map { |resource_type| searchworks_resource_type(resource_type) }
        mapped_values << "Dataset" if dataset?
        mapped_values.uniq
      end

      # Physical or digital forms of the object.
      # @return [Array<String>]
      # @example GIS dataset (nz187ct8959)
      #   record.forms #=> ["map", "optical disc", "electronic resource"]
      def forms
        form_objects.filter { |form| form.type == "form" }.map(&:to_s).compact_blank.uniq
      end

      # Extent of the object, such as "1 audiotape" or "1 map".
      # @return [Array<String>]
      # @example Oral history interview (sw705fr7011)
      #   record.extents #=> ["1 audiotape", "1 transcript"]
      def extents
        form_objects.filter { |form| form.type == "extent" }.map(&:to_s).compact_blank.uniq
      end

      # Genres of the object, capitalized for display.
      # @return [Array<String>]
      # @example GIS dataset (nz187ct8959)
      #   record.genres #=> ["Cartographic dataset", "Geospatial data", "Geographic information systems data"]
      def genres
        form_objects.filter { |form| form.type == "genre" }.map(&:to_s).compact_blank.uniq
      end

      # Genres of the object, with additional values added for search/faceting.
      # @note These values are added for discovery in SearchWorks but not for display.
      # @return [Array<String>]
      def genres_search
        genres.tap do |values|
          values << "Thesis/Dissertation" if values.include?("Thesis")
          values << "Conference proceedings" if values.include?("Conference publication")
          values << "Government document" if values.include?("Government publication")
        end.uniq
      end

      # All map-related data to be rendered for display as a single value.
      # Includes map scale, projection info, and geographic coordinate subjects.
      # @return [Array<DisplayData>]
      def map_display_data
        Utils.display_data_from_objects(
          form_objects.filter { |form| ["map scale", "map projection"].include?(form.type) } +
          coordinate_subjects
        )
      end

      # Is the object a periodical or serial?
      # @return [Boolean]
      def periodical?
        issuance_terms.include?("periodical") || issuance_terms.include?("serial") || frequency.any?
      end

      # Is the object a cartographic resource?
      # @return [Boolean]
      def cartographic?
        resource_type_values.include?("cartographic")
      end

      # Is the object a web archive?
      # @return [Boolean]
      def archived_website?
        genres.include?("Archived website")
      end

      # Is the object a dataset?
      # @return [Boolean]
      def dataset?
        genres.include?("Dataset")
      end

      private

      # Collapses all nested form values into an array of {Form} objects.
      # @return [Array<Form>]
      def form_objects
        @form_objects ||= path("$.description.form.*")
          .flat_map { |form| Utils.flatten_nested_values(form) }
          .map { |form| CocinaDisplay::Forms::Form.new(form) }
      end

      # Map a resource type to SearchWorks format value(s).
      # @param resource_type [String] The resource type to map.
      # @return [Array<String>]
      def searchworks_resource_type(resource_type)
        values = []

        case resource_type
        when "cartographic"
          values << "Map"
        when "manuscript", "mixed material"
          values << "Archive/Manuscript"
        when "moving image"
          values << "Video"
        when "notated music"
          values << "Music score"
        when "software, multimedia"
          # Prevent GIS datasets from being labeled as "Software"
          values << "Software/Multimedia" unless cartographic? || dataset?
        when "sound recording-musical"
          values << "Music recording"
        when "sound recording-nonmusical", "sound recording"
          values << "Sound recording"
        when "still image"
          values << "Image"
        when "text"
          # Can potentially map to periodical AND website if both are true. Only
          # 2 records currently (2025) in Searchworks do this, but it is real.
          if periodical? || archived_website?
            values << "Journal/Periodical" if periodical?
            values << "Archived website" if archived_website?
          else
            values << "Book"
          end
        when "three dimensional object"
          values << "Object"
        end

        values.compact_blank
      end

      # Issuance terms for a work, drawn from the event notes.
      # @return [Array<String>]
      def issuance_terms
        path("$.description.event.*.note[?@.type == 'issuance'].value").map(&:downcase).uniq
      end

      # Frequency terms for a periodical, drawn from the event notes.
      # @return [Array<String>]
      def frequency
        path("$.description.event.*.note[?@.type == 'frequency'].value").map(&:downcase).uniq
      end

      # Values of the resource type form field prior to mapping.
      # @return [Array<String>]
      def resource_type_values
        path("$.description.form..[?@.type == 'resource type'].value").uniq
      end
    end
  end
end
