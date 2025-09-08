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
        form_forms.map(&:to_s).compact_blank.uniq
      end

      # Extent of the object, such as "1 audiotape" or "1 map".
      # @return [Array<String>]
      # @example Oral history interview (sw705fr7011)
      #   record.extents #=> ["1 audiotape", "1 transcript"]
      def extents
        extent_forms.map(&:to_s).compact_blank.uniq
      end

      # Genres of the object, capitalized for display.
      # @return [Array<String>]
      # @example GIS dataset (nz187ct8959)
      #   record.genres #=> ["Cartographic dataset", "Geospatial data", "Geographic information systems data"]
      def genres
        genre_forms.map(&:to_s).compact_blank.uniq
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

      # All form-related data to be rendered for display.
      # Includes form, extent, resource type, etc.
      # @return [Array<DisplayData>]
      def form_display_data
        CocinaDisplay::DisplayData.from_objects(all_forms - genre_forms - map_forms - media_forms)
      end

      # All genre-related data to be rendered for display.
      # Includes both form genres and subject genres.
      # @return [Array<DisplayData>]
      def genre_display_data
        CocinaDisplay::DisplayData.from_objects(genre_forms + genre_subjects)
      end

      # All map-related data to be rendered for display.
      # Includes map scale, projection info, and geographic coordinate subjects.
      # @return [Array<DisplayData>]
      def map_display_data
        CocinaDisplay::DisplayData.from_objects(map_forms + coordinate_subjects)
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
      # Preserves resource type without flattening, since it can be structured.
      # @return [Array<Form>]
      def all_forms
        @all_forms ||= path("$.description.form.*")
          .flat_map { |form| Utils.flatten_nested_values(form, atomic_types: ["resource type"]) }
          .map { |form| CocinaDisplay::Forms::Form.new(form) }
      end

      # {Form} objects with type "form".
      # @return [Array<Form>]
      def form_forms
        all_forms.filter { |form| form.type == "form" }
      end

      # {Form} objects with type "genre".
      # @return [Array<Form>]
      def genre_forms
        all_forms.filter { |form| form.type == "genre" }
      end

      # {Form} objects with type "extent".
      # @return [Array<Form>]
      def extent_forms
        all_forms.filter { |form| form.type == "extent" }
      end

      # {Form} objects with types related to map data.
      # @return [Array<Form>]
      def map_forms
        all_forms.filter { |form| ["map scale", "map projection"].include?(form.type) }
      end

      # {Form} objects with types that are media-related.
      # @note These are excluded from the general form display data.
      # @return [Array<Form>]
      def media_forms
        all_forms.filter { |form| ["reformatting quality", "media type"].include?(form.type) }
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
