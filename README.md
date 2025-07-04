# CocinaDisplay

[![Build Status](https://github.com/sul-dlss/cocina_display/workflows/CI/badge.svg)](https://github.com/sul-dlss/cocina_display/actions)
[![Docs Status](https://github.com/sul-dlss/cocina_display/actions/workflows/docs.yml/badge.svg)](https://github.com/sul-dlss/cocina_display/actions/workflows/docs.yml)
[![Gem Version](https://badge.fury.io/rb/cocina_display.svg)](https://badge.fury.io/rb/cocina_display)

Helpers for rendering Cocina metadata in Rails applications and indexing pipelines.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add cocina_display
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install cocina_display
```

## Usage

### Obtaining Cocina

To start, you need some Cocina in JSON form. 

You can download some directly from PURL by visiting an object's PURL URL and appending `.json` to the end, like `https://purl.stanford.edu/bb112zx3193.json`. Some examples are available in the `spec/fixtures` directory.

You can also use the built-in `HTTP` library or `faraday` gem to fetch the record for you, e.g.:

```ruby
require 'http'
cocina_json = HTTP.get('https://purl.stanford.edu/bb112zx3193.json').to_s
```

### Working with objects

Once you have the JSON, you can initialize a `CocinaRecord` object and start working with it. The `CocinaRecord` class provides some methods to access common fields, as well as an underlying hash representation parsed from the JSON.

```ruby
> require 'cocina_display/cocina_record'
=> true
> record = CocinaDisplay::CocinaRecord.new(cocina_json)
=>
#<CocinaDisplay::CocinaRecord:0x000000012d11b600
...
> record.title
=> "Bugatti Type 51A. Road & Track Salon January 1957"
> record.content_type
=> "image"
> record.iiif_manifest_url 
=> "https://purl.stanford.edu/bb112zx3193/iiif3/manifest"
# access the hash representation
> record.cocina_doc.dig("description", "contributor", 0, "name", 0, "value")  
=> "Hearst Magazines, Inc."
```

See the [API Documentation](https://sul-dlss.github.io/cocina_display/CocinaDisplay/CocinaRecord.html) for more details on the methods available in the `CocinaRecord` class.

### Fetching nested data

Fetching data deeply nested in the record, especially when you need to filter based on some criteria, can be tedious. The `CocinaRecord` class also provides a method called `#path` that accepts a JsonPath expression to retrieve data in a more concise way.

The previous example used `Hash#dig` to access the first contributor's first name value. Using `#path`, you can query for _all_ contributor name values, or even filter to particular contributors:

```ruby
# name values for all contributors in description
> record.path('$.description.contributor[*].name[*].value').search
=> ["Hearst Magazines, Inc.", "Chesebrough, Jerry"]
# only contributors with a role with value "photographer"
> record.path("$.description.contributor[?@.role[?@.value == 'photographer']].name[*].value").search
=> ["Chesebrough, Jerry"]
```

The JsonPath implementation used is [janeway](https://www.rubydoc.info/gems/janeway-jsonpath/0.6.0/file/README.md), which supports the full syntax from the [finalized 2024 version of the specification](https://www.rfc-editor.org/rfc/rfc9535.html). Results returned from `#path` are Enumerators.

In the following example, we start an expression with `"$.."` to search for contributor nodes at _any_ level (e.g. `event.contributors`) and discover that there is a third contributor, but it has no `name` value. Using the `['code', 'value']` syntax, we can retrieve both `code` and `value` and show where they came from:

```ruby
> record.path("$..contributor[*].name[*]['code', 'value']").each { |value, node, key| puts "#{key}: #{value} (from #{node})" }
value: Hearst Magazines, Inc. (from {"structuredValue"=>[], "parallelValue"=>[], "groupedValue"=>[], "value"=>"Hearst Magazines, Inc.", "uri"=>"http://id.loc.gov/authorities/names/n2015050736", "identifier"=>[], "source"=>{"code"=>"naf", "uri"=>"http://id.loc.gov/authorities/names/", "note"=>[]}, "note"=>[], "appliesTo"=>[]})
value: Chesebrough, Jerry (from {"structuredValue"=>[], "parallelValue"=>[], "groupedValue"=>[], "value"=>"Chesebrough, Jerry", "identifier"=>[], "note"=>[], "appliesTo"=>[]})
code: CSt (from {"structuredValue"=>[], "parallelValue"=>[], "groupedValue"=>[], "code"=>"CSt", "uri"=>"http://id.loc.gov/vocabulary/organizations/cst", "identifier"=>[], "source"=>{"code"=>"marcorg", "uri"=>"http://id.loc.gov/vocabulary/organizations", "note"=>[]}, "note"=>[], "appliesTo"=>[]})
=> ["Hearst Magazines, Inc.", "Chesebrough, Jerry", "CSt"]
```

There is also a command line utility for quickly querying a JSON file using JsonPath. Online syntax checkers may give different results, so it helps to test locally. You can run it with:

```bash
cat spec/fixtures/bb112zx3193.json | janeway "$.description.contributor[?@.role[?@.value == 'photographer']].name[*].value"
[
  "Chesebrough, Jerry"
]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Documentation is generated using [yard](https://yardoc.org). You can generate it by running `yardoc`, or `yard server --reload` to start a local server and watch for changes as you edit.

## Background

Historically, applications at SUL used a combination of several gems to render objects represented by MODS XML. With the transition to the Cocina data model, infrastructure applications adopted the [cocina-models gem](https://github.com/sul-dlss/cocina-models), which provides accessor objects and validators over Cocina JSON. Internal applications can fetch such objects over HTTP using [dor-services-client](https://github.com/sul-dlss/dor-services-client).

On the access side, Cocina JSON (the "public Cocina") is available statically via [PURL](https://purl.stanford.edu), but is only updated when an object is published ("shelved") from SDR. This frequently results in data that is technically invalid with respect to `cocina-models` but is still valid in the context of a patron-facing application.

Cocina data can also be complex, representing the same underlying information in different ways. A "complete" implementation can involve checking multiple deeply nested paths to ensure no information is missed. Rather than tightly coupling access applications to `cocina-models`, this gem provides a set of helpers designed to safely parse Cocina JSON and render it in a consistent way across applications.

The intent is that both applications that directly render SDR metadata as HTML (PURL, Exhibits) and applications that index it for later display in a catalog (Searchworks, Earthworks, Dataworks) can adopt a single gem for rendering Cocina in a human-readable way. This gem **does not** aim to render HTML or provide view components – that is the responsibility of the consuming application.
