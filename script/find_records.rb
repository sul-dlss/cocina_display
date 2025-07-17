# frozen_string_literal: true

# This script is a simple, brute-force method for finding records that
# exhibit certain characteristics in the public Cocina JSON for testing.
#
# It queries purl-fetcher for all DRUIDs released to a specific target and
# then fetches each corresponding public Cocina record from PURL and examines it.
#
# You need to be on VPN to do this, as the purl-fetcher API is only accessible
# from within the Stanford network.
#
# To use, modify any of the noted items below, then run:
# $ bundle exec ruby script/find_records.rb
#
# You can exit early with Ctrl-C, and it will report how many records were
# checked before exiting. Running through an entire target will take awhile,
# on the order of 30 minutes or more.

require "benchmark"
require "pp"
require "purl_fetcher/client"
require "cocina_display"
require "cocina_display/utils"

# This should correspond to one of the release targets available in purl-fetcher,
# i.e. "Searchworks", "Earthworks", etc.
RELEASE_TARGET = "Searchworks"

# Modify this expression to match the JSON path you want to search, or just
# modify the `examine_record` method directly.
PATH_EXPR = "$..[?length(@.groupedValue) > 0]"

# Modify this method as needed to change what you're looking for in each record.
# It takes a CocinaRecord object and should return an array of [path, result] pairs.
def examine_record(record)
  record.path(PATH_EXPR).map { |value, _node, _key, path| [path, CocinaDisplay::Utils.deep_compact_blank(value)] }
end

# Track total records in target and how many we've seen
released_to_target = []
processed_records = 0

# Handle Ctrl-C gracefully
Signal.trap("INT") do
  puts "\nExiting after processing #{processed_records} records."
  exit
end

# Fetch everything from purl-fetcher; note that this is one single HTTP request
# that returns a massive JSON response – it can be quite slow
puts "Finding records released to #{RELEASE_TARGET}..."
client = PurlFetcher::Client::Reader.new
query_time = Benchmark.realtime do
  client.released_to(RELEASE_TARGET).each do |record|
    released_to_target << record["druid"].delete_prefix("druid:")
  end
rescue Faraday::ConnectionFailed => e
  puts "Connection failed: #{e.message}; are you on VPN?"
  exit 1
end
puts "Found #{released_to_target.size} records released to #{RELEASE_TARGET} in #{query_time.round(2)} seconds"

# Iterate through the list of DRUIDs and fetch each one from PURL, creating a
# CocinaRecord object. Then call our examine_record method on it and if
# anything was returned, print the DRUID and the results.
released_to_target.each do |druid|
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
