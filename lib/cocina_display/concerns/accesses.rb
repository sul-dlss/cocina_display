module CocinaDisplay
  module Concerns
    # Methods for extracting access/location information from a Cocina object.
    module Accesses
      # Display data for all access metadata except contact emails
      # @return [Array<DisplayData>]
      def access_display_data
        CocinaDisplay::DisplayData.from_objects(accesses +
                                                access_contacts.reject(&:contact_email?) +
                                                purls +
                                                urls)
      end

      # Display data for all access contact email metadata
      # @return [Array<DisplayData>]
      def contact_email_display_data
        CocinaDisplay::DisplayData.from_objects(access_contacts.select(&:contact_email?))
      end

      # Display data for the use and reproduction statement.
      # Exhibits and EarthWorks handle useAndReproductionStatement like descriptive metadata.
      # @return [Array<CocinaDisplay::DisplayData>]
      def use_and_reproduction_display_data
        CocinaDisplay::DisplayData.from_strings([use_and_reproduction],
          label: I18n.t("cocina_display.field_label.use_and_reproduction"))
      end

      # Display data for the copyright statement.
      # Exhibits and EarthWorks handle copyright like descriptive metadata.
      # @return [Array<CocinaDisplay::DisplayData>]
      def copyright_display_data
        CocinaDisplay::DisplayData.from_strings([copyright],
          label: I18n.t("cocina_display.field_label.copyright"))
      end

      def license_display_data
        CocinaDisplay::DisplayData.from_strings([license_description],
          label: I18n.t("cocina_display.field_label.license"))
      end

      # All access metadata except contact emails and URLs
      # @return [Array<Description::Access>]
      def accesses
        @accesses ||= Enumerator::Chain.new(
          path("$.description.access.physicalLocation.*"),
          path("$.description.access.digitalLocation.*"),
          path("$.description.access.digitalRepository.*")
        ).map { |a| CocinaDisplay::Description::Access.new(a) }
      end

      # All access contact metadata
      # @return [Array<Description::AccessContact>]
      def access_contacts
        path("$.description.access.accessContact.*").map do |contact|
          CocinaDisplay::Description::AccessContact.new(contact)
        end
      end

      # All access URL metadata
      # @return [Array<Description::Url>]
      def urls
        path("$.description.access.url.*").map do |url|
          CocinaDisplay::Description::Url.new(url)
        end
      end

      # View rights for the object.
      # @return [String, nil]
      # @example "world", "stanford_only", "dark", "location-based"
      def view_rights
        path("$.access.view").first
      end

      # Download rights for the object.
      # @note Individual files may have differing download rights.
      # @return [String, nil]
      # @example "world", "stanford_only", "none", "location-based"
      def download_rights
        path("$.access.download").first
      end

      # If access or download is location-based, which location has access.
      # @return [String, nil]
      # @example "spec", "music", "ars", "art", "hoover", "m&m"
      def location_rights
        path("$.access.location").first
      end

      # Is the object viewable in some capacity?
      # @return [Boolean]
      def viewable?
        view_rights != "dark"
      end

      # Is the object downloadable in some capacity?
      # @return [Boolean]
      def downloadable?
        download_rights != "none"
      end

      # Is the object viewable by anyone?
      # @return [Boolean]
      def world_viewable?
        view_rights == "world"
      end

      # Is the object downloadable by anyone?
      # @return [Boolean]
      def world_downloadable?
        download_rights == "world"
      end

      # Is the object both viewable and downloadable by anyone?
      # @return [Boolean]
      def world_access?
        world_viewable? && world_downloadable?
      end

      # Is the object only viewable by Stanford affiliates?
      # @return [Boolean]
      def stanford_only_viewable?
        view_rights == "stanford"
      end

      # Is the object only downloadable by Stanford affiliates?
      # @return [Boolean]
      def stanford_only_downloadable?
        download_rights == "stanford"
      end

      # Is the object only viewable and downloadable by Stanford affiliates?
      # @return [Boolean]
      def stanford_only_access?
        stanford_only_viewable? && stanford_only_downloadable?
      end

      # Is the object viewable by Stanford affiliates?
      # @return [Boolean]
      def stanford_viewable?
        world_viewable? || stanford_only_viewable?
      end

      # Is the object downloadable by Stanford affiliates?
      # @return [Boolean]
      def stanford_downloadable?
        world_downloadable? || stanford_only_downloadable?
      end

      # Is the object both viewable and downloadable by Stanford affiliates?
      # @return [Boolean]
      def stanford_access?
        stanford_viewable? && stanford_downloadable?
      end

      # Is the object "dark" (not viewable or downloadable by anyone)?
      # @return [Boolean]
      def dark_access?
        !viewable? && !downloadable?
      end

      # Is the object viewable only if in a location?
      # @return [Boolean]
      def location_only_viewable?
        view_rights == "location-based"
      end

      # Is the object downloadable only if in a location?
      # @return [Boolean]
      def location_only_downloadable?
        download_rights == "location-based"
      end

      # Is the object only viewable and downloadable if in a location?
      # @return [Boolean]
      def location_only_access?
        location_only_viewable? && location_only_downloadable?
      end

      # Is the object viewable at the given location?
      # @param location [String] The location to check
      # @return [Boolean]
      def viewable_at_location?(location)
        world_viewable? || stanford_viewable? || location_rights == location
      end

      # Is the object only viewable for citation purposes?
      # @return [Boolean]
      def citation_only_access?
        view_rights == "citation-only"
      end

      private

      # The Purl URL to combine with other access metadata
      # @return [Array<DescriptiveValue>]
      def purls
        return [] unless purl_url.present?

        CocinaDisplay::DisplayData.descriptive_values_from_strings([purl_url], label: I18n.t("cocina_display.field_label.purl"))
      end
    end
  end
end
