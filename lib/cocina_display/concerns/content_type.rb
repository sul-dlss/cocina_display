module CocinaDisplay
  module Concerns
    # Methods related to the content type of a Cocina object.
    module ContentType
      # SDR content type of the object.
      # @return [String, nil]
      # @see https://github.com/sul-dlss/cocina-models/blob/main/openapi.yml#L532-L546
      # @example
      #  record.content_type #=> "image"
      def content_type
        cocina_doc["type"]&.delete_prefix("https://cocina.sul.stanford.edu/models/")
      end

      # True if the object is a collection.
      # @return [Boolean]
      def collection?
        content_type == "collection"
      end
    end
  end
end
