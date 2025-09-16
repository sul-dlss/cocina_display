module CocinaDisplay
  module Concerns
    # Methods for extracting and formatting related resources from Cocina records.
    module RelatedResources
      # Resources related to the object.
      # @return [Array<CocinaDisplay::RelatedResource>]
      def related_resources
        @related_resources ||= path("$.description.relatedResource[*]").map { |res| RelatedResource.new(res) }
      end

      # Display data for related resources.
      # @note Related resources also have their own nested display data.
      # @see CocinaDisplay::RelatedResource#display_data
      # @return [Array<DisplayData>]
      def related_resource_display_data
        DisplayData.from_objects(related_resources)
      end
    end
  end
end
