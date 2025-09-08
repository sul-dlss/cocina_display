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

      # All access metadata except contact emails and URLs
      # @return [Array<Access>]
      def accesses
        @accesses ||= Enumerator::Chain.new(
          path("$.description.access.physicalLocation.*"),
          path("$.description.access.digitalLocation.*"),
          path("$.description.access.digitalRepository.*")
        ).map { |a| CocinaDisplay::Access.new(a) }
      end

      # All access contact metadata
      # @return [Array<Accesses::AccessContact>]
      def access_contacts
        path("$.description.access.accessContact.*").map do |contact|
          CocinaDisplay::Accesses::AccessContact.new(contact)
        end
      end

      # All access URL metadata
      # @return [Array<Accesses::Url>]
      def urls
        path("$.description.access.url.*").map do |url|
          CocinaDisplay::Accesses::Url.new(url)
        end
      end

      private

      # The Purl URL to combine with other access metadata
      # @return [Array<DescriptiveValue>]
      def purls
        return [] unless purl_url.present?

        CocinaDisplay::DisplayData.descriptive_values_from_string(purl_url, label: I18n.t("cocina_display.field_label.purl"))
      end
    end
  end
end
