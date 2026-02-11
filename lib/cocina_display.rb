# frozen_string_literal: true

# require_relative "cocina_display/version"

require "janeway"
require "json"
require "net/http"
require "active_support"
require "active_support/core_ext"
require "geo/coord"
require "edtf"
require "i18n"
require "i18n/backend/fallbacks"
I18n::Backend::Simple.include I18n::Backend::Fallbacks
I18n.load_path += Dir["#{File.expand_path("..", __dir__)}/config/locales/*.yml"]
I18n.backend.load_translations

require "zeitwerk"
loader = Zeitwerk::Loader.new
loader.tag = File.basename(__FILE__, ".rb")
loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
loader.push_dir(File.dirname(__FILE__))
loader.setup

module CocinaDisplay
  # set to an object with a #notify method. This is called if an error is encountered.
  mattr_accessor :notifier

  # @return [Pathname] Returns the root path of this gem
  def self.root
    @root ||= Pathname.new(File.expand_path("..", __dir__))
  end
end
