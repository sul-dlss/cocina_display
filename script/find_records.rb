# frozen_string_literal: true

# This script is a simple, brute-force method for finding records that
# exhibit certain characteristics in the public Cocina JSON for testing.
#
# It reads the public PURL sitemap to enumerate all released DRUIDs and then
# fetches each corresponding public Cocina record from PURL and examines it.
#
# To use, modify any of the noted items below, then run:
# $ bundle exec ruby script/find_records.rb
#
# You can exit early with Ctrl-C, and it will report how many records were
# checked before exiting. Running through the entire sitemap will take awhile,
# on the order of 30 minutes or more.

require "benchmark"
require "net/http"
require "pp"
require "rexml/document"
require "stringio"
require "uri"
require "zlib"
require "cocina_display"
require "cocina_display/utils"

# The PURL sitemap index. This points to one or more gzipped child sitemaps,
# each of which lists PURL URLs (one per released DRUID).
SITEMAP_URL = "https://purl.stanford.edu/system/sitemap/sitemap.xml.gz"

# Modify this expression to match the JSON path you want to search, or just
# modify the `examine_record` method directly.
PATH_EXPR = "$..[? @.type == 'parallel' ]"

# Modify this method as needed to change what you're looking for in each record.
# It takes a CocinaRecord object and should return an array of [path, result] pairs.
def examine_record(record)
  record.path(PATH_EXPR).map { |value, _node, _key, path| [path, CocinaDisplay::Utils.deep_compact_blank(value)] }
end

# Fetch a URL and return the response body, transparently decompressing it if
# it was served (or named) as gzip.
def fetch_gzipped(url)
  body = Net::HTTP.get(URI(url))
  Zlib::GzipReader.new(StringIO.new(body)).read
rescue Zlib::GzipFile::Error
  body
end

# Extract every <loc> value from a sitemap or sitemap index document.
def sitemap_locs(xml)
  REXML::Document.new(xml).get_elements("//loc").map { |loc| loc.text.strip }
end

# Walk the sitemap index and yield the DRUID for every URL in each child sitemap.
def each_druid_in_sitemap(sitemap_url)
  return enum_for(:each_druid_in_sitemap, sitemap_url) unless block_given?

  sitemap_locs(fetch_gzipped(sitemap_url)).each do |child_sitemap_url|
    sitemap_locs(fetch_gzipped(child_sitemap_url)).each do |purl_url|
      yield File.basename(URI(purl_url).path)
    end
  end
end

# Track total records and how many we've seen
druids = []
processed_records = 0

# Handle Ctrl-C gracefully
Signal.trap("INT") do
  puts "\nExiting after processing #{processed_records} records."
  exit
end

# Read the sitemap; this involves a handful of HTTP requests (the index plus
# each child sitemap) that are relatively quick compared to purl-fetcher.
puts "Finding released records from the PURL sitemap..."
query_time = Benchmark.realtime do
  each_druid_in_sitemap(SITEMAP_URL) { |druid| druids << druid }
rescue => e
  puts "Failed to read sitemap: #{e.message}"
  exit 1
end
puts "Found #{druids.size} records in the sitemap in #{query_time.round(2)} seconds"

# Iterate through the list of DRUIDs and fetch each one from PURL, creating a
# CocinaRecord object. Then call our examine_record method on it and if
# anything was returned, print the DRUID and the results.
druids.each do |druid|
  begin
    cocina_record = CocinaDisplay::CocinaRecord.fetch(druid)
    processed_records += 1
  rescue => e
    puts "Error fetching record #{druid}: #{e.message}"
    next
  end

  results = examine_record(cocina_record)
  next if results.empty?

  puts "Druid: #{druid}"
  results.each do |path, result|
    puts "  Path: #{path}"
    puts "  Result: #{result.pretty_inspect}\n"
  end

  puts "-" * 80
end
