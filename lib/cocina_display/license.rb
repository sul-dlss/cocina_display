# frozen_string_literal: true

module CocinaDisplay
  # A license associated with part or all of a Cocina object.
  # This is the license entity used for translating a license URL into text
  # for display.
  class License
    LICENSE_FILE_PATH = File.join(__dir__, "..", "..", "config", "licenses.yml").freeze

    attr_reader :description, :uri

    # Raised when the license provided is not valid
    class LegacyLicenseError < StandardError; end

    # A hash of license URLs to their description attributes
    # @return [Hash{String => Hash{String => String}}]
    def self.licenses
      @licenses ||= YAML.safe_load_file(LICENSE_FILE_PATH)
    end

    # Initialize a License from a license URL.
    # @param url [String] The license URL.
    # @raise [LegacyLicenseError] if the license URL is not in the config
    def initialize(url:)
      raise LegacyLicenseError unless License.licenses.key?(url)

      attrs = License.licenses.fetch(url)
      @uri = url
      @description = attrs.fetch("description")
    end
  end
end
