module CocinaDisplay
  module Concerns
    # Methods for extracting and formatting identifiers from Cocina records.
    module Identifiers
      # The DRUID for the object, with the +druid:+ prefix.
      # @note A {RelatedResource} may not have a DRUID.
      # @return [String, nil]
      # @example
      #   record.druid #=> "druid:bb099mt5053"
      def druid
        cocina_doc["externalIdentifier"] ||
          cocina_doc.dig("description", "purl")&.split("/")&.last
      end

      # The DRUID for the object, without the +druid:+ prefix.
      # @note A {RelatedResource} may not have a DRUID.
      # @return [String, nil]
      # @example
      #   record.bare_druid #=> "bb099mt5053"
      def bare_druid
        druid&.delete_prefix("druid:")
      end

      # The DOI for the object, if there is one – just the identifier part.
      # @return [String, nil]
      # @example
      #   record.doi #=> "10.25740/ppax-bf07"
      def doi
        doi_id = path("$.identification.doi").first ||
          path("$.description.identifier[?match(@.type, 'doi|DOI')].value").first ||
          path("$.description.identifier[?search(@.uri, 'doi.org')].uri").first

        URI(doi_id).path.delete_prefix("/") if doi_id.present?
      end

      # The DOI as a URL, if there is one. Any valid DOI should resolve via doi.org.
      # @return [String, nil]
      # @example
      #   record.doi_url #=> "https://doi.org/10.25740/ppax-bf07"
      def doi_url
        URI.join("https://doi.org", doi).to_s if doi.present?
      end

      # The HRID of the item in FOLIO, if defined.
      # @note This doesn't imply the object is available in Searchworks at this ID.
      # @param [refresh] [Boolean] Filter to links with refresh set to this value.
      # @return [String, nil]
      # @example With a link regardless of refresh:
      #   record.folio_hrid #=> "a12845814"
      # @example With a link that is not refreshed:
      #   record.folio_hrid(refresh: true) #=> nil
      def folio_hrid(refresh: nil)
        link = path("$.identification.catalogLinks[?(@.catalog == 'folio')]").first
        hrid = link&.dig("catalogRecordId")
        return if hrid.blank?
        return hrid if refresh.nil?

        (link["refresh"] == refresh) ? hrid : nil
      end

      # The FOLIO HRID if defined, otherwise the bare DRUID.
      # @note This doesn't imply the object is available in Searchworks at this ID.
      # @see folio_hrid
      # @see bare_druid
      # @return [String, nil]
      def searchworks_id
        folio_hrid || bare_druid
      end
    end
  end
end
