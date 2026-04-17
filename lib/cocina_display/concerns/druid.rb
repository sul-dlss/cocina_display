module CocinaDisplay
  module Concerns
    # Methods for extracting and formatting identifiers from Cocina records.
    module Druid
      # The DRUID for the object, with the +druid:+ prefix.
      # @note A {RelatedResource} may not have a DRUID, but could have a purl URL.
      # @return [String, nil]
      # @example
      #   record.druid #=> "druid:bb099mt5053"
      def druid
        cocina_doc["externalIdentifier"]
      end

      # The DRUID for the object, without the +druid:+ prefix.
      # @note A {RelatedResource} may not have a DRUID.
      # @return [String, nil]
      # @example
      #   record.bare_druid #=> "bb099mt5053"
      def bare_druid
        druid.delete_prefix("druid:")
      end
    end
  end
end
