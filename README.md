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

To start, you need some Cocina in JSON form. Consumers of this gem are likely to be applications that are already harvesting this data (for indexing) or have it stored in an index or database (for display). In testing, you may have neither of these.

You can download some directly from PURL by visiting an object's PURL URL and appending `.json` to the end, like `https://purl.stanford.edu/bb112zx3193.json`. Some examples are available in the `spec/fixtures` directory.

There is also a helper method to fetch the Cocina JSON for a given DRUID over HTTP and immediately parse it into a `CocinaRecord` object:

```ruby
> record = CocinaDisplay::CocinaRecord.fetch('bb112zx3193')
=> #<CocinaDisplay::CocinaRecord:0x00007f8c8c0b5c80
```

### Working with objects

The `CocinaRecord` class provides some methods to access common fields, as well as an underlying hash representation parsed from the JSON.

```ruby
> record.main_title
=> "Bugatti Type 51A. Road & Track Salon January 1957"
> record.content_type
=> "image"
> record.iiif_manifest_url 
=> "https://purl.stanford.edu/bb112zx3193/iiif3/manifest"
# access the hash representation
> record.cocina_doc.dig("description", "contributor", 0, "name", 0, "value")  
=> "Hearst Magazines, Inc."
```

See the [API Documentation](https://sul-dlss.github.io/cocina_display/CocinaDisplay/CocinaRecord.html) for more details on the methods available in the `CocinaRecord` class. The gem provides a large number of methods, organized into concerns, to access different parts of the data.

### Fetching nested data

Fetching data deeply nested in the record, especially when you need to filter based on some criteria, can be tedious. The `CocinaRecord` class also provides a method called `#path` that accepts a JsonPath expression to retrieve data in a more concise way.

The previous example used `Hash#dig` to access the first contributor's first name value. Using `#path`, you can query for _all_ contributor name values, or even filter to particular contributors:

```ruby
# name values for all contributors in description
> record.path('$.description.contributor.*.name.*.value').search
=> ["Hearst Magazines, Inc.", "Chesebrough, Jerry"]
# only contributors with a role with value "photographer"
> record.path("$.description.contributor[?@.role[?@.value == 'photographer']].name.*.value").search
=> ["Chesebrough, Jerry"]
```

The JsonPath implementation used is [janeway](https://www.rubydoc.info/gems/janeway-jsonpath/0.6.0/file/README.md), which supports the full syntax from the [finalized 2024 version of the specification](https://www.rfc-editor.org/rfc/rfc9535.html). Results returned from `#path` are Enumerators.

In the following example, we start an expression with `"$.."` to search for contributor nodes at _any_ level (e.g. `event.contributors`) and discover that there is a third contributor, but it has no `name` value. Using the `['code', 'value']` syntax, we can retrieve both `code` and `value` and show the path they came from:

```ruby
> record.path("$..contributor.*.name[*]['code', 'value']").map { |value, _node, key, path| [key, value, path] }
[["value", "Hearst Magazines, Inc.", "$['description']['contributor'][0]['name'][0]['value']"],
 ["value", "Chesebrough, Jerry", "$['description']['contributor'][1]['name'][0]['value']"],
 ["code", "CSt", "$['description']['adminMetadata']['contributor'][0]['name'][0]['code']"]]
```

There is also a command line utility for quickly querying a JSON file using JsonPath. Online syntax checkers may give different results, so it helps to test locally. You can run it with:

```bash
cat spec/fixtures/bb112zx3193.json | janeway "$.description.contributor[?@.role[?@.value == 'photographer']].name.*.value"
[
  "Chesebrough, Jerry"
]
```

### Searching for records

Sometimes you need to determine if records exist "in the wild" that exhibit particular characteristics in the Cocina metadata, like the presence or absence of a field, or a specific value in a field. There is a template script in the `scripts/` directory that can be used to crawl all DRUIDs released to a particular target, like Searchworks, and examine each record.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. This is a useful place to try out JSONPath expressions with `CocinaRecord#path`.

Tests are written using [rspec](https://rspec.info), with coverage automatically measured via [simplecov](https://github.com/simplecov-ruby/simplecov). CI will fail if coverage drops below 100%. For convenience, if you invoke a single spec file locally, coverage will not be reported.

Documentation is generated using [yard](https://yardoc.org). You can generate it locally by running `yardoc`, or `yard server --reload` to start a local server and watch for changes as you edit. There is a GitHub action that automatically generates and publishes the documentation to GitHub Pages on every push/merge to `main`.

To release a new version, update the version number in `version.rb`, run `bundle` to update `Gemfile.lock`, commit your changes, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Background

Historically, applications at SUL used a combination of several gems to render objects represented by MODS XML. With the transition to the Cocina data model, infrastructure applications adopted the [cocina-models gem](https://github.com/sul-dlss/cocina-models), which provides accessor objects and validators over Cocina JSON. Internal applications can fetch such objects over HTTP using [dor-services-client](https://github.com/sul-dlss/dor-services-client).

On the access side, Cocina JSON (the "public Cocina") is available statically via [PURL](https://purl.stanford.edu), but is only updated when an object is published ("shelved") from SDR. This frequently results in data that is technically invalid with respect to `cocina-models` (i.e. it does not match the latest spec) but is still valid in the context of a patron-facing application (because it can still be rendered into useful information).

Cocina data can also be complex, representing the same underlying information in different ways. A "complete" implementation can involve checking multiple deeply nested paths to ensure no information is missed. Rather than tightly coupling access applications to `cocina-models`, this gem provides a set of helpers designed to safely parse Cocina JSON and render it in a consistent way across applications.

The intent is that both applications that directly render SDR metadata as HTML (PURL, Exhibits) and applications that index it for later display in a catalog (Searchworks, Earthworks, Dataworks) can adopt a single gem for rendering Cocina in a human-readable way. This gem **does not** aim to render HTML or provide view components – that is the responsibility of the consuming application.
