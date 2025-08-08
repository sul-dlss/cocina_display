# frozen_string_literal: true

# Given a JSON data structure from stdin, recursively remove empty keys and
# blank values to create a more compact representation and write to stdout.

require "json"

require_relative "../lib/cocina_display/utils"

input = $stdin.read
data = JSON.parse(input)
compact_data = CocinaDisplay::Utils.deep_compact_blank(data)
$stdout.puts JSON.generate(compact_data)
