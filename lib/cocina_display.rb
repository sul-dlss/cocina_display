# frozen_string_literal: true

# require_relative "cocina_display/version"

require "janeway"
require "json"
require "net/http"
require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/conversions"
require "geo/coord"
require "edtf"
require "iso639"

require "zeitwerk"
loader = Zeitwerk::Loader.new
loader.tag = File.basename(__FILE__, ".rb")
loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
loader.inflector.inflect("searchworks_languages" => "SEARCHWORKS_LANGUAGES",
  "marc_relator" => "MARC_RELATOR",
  "marc_country" => "MARC_COUNTRY")
loader.push_dir(File.dirname(__FILE__))
loader.setup
