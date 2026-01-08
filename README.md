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
> record.short_title
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

### Formatting for display

Methods ending in `_display_data` usually return arrays of a class called `DisplayData`, which is designed for rendering into HTML by a consuming application. Each `DisplayData` object has a `label`, which serves as a heading under which its data is grouped. The `values` method returns an array of strings, which are the individual values to be displayed under that heading.

For example, when displaying contributors, the label is usually determined by the role of the contributor, and the values are the display names of the contributors with that role:

```ruby
> rec.contributor_display_data.first.label
=> "Former owner"
> rec.contributor_display_data.first.values
=> ["Hearst Magazines, Inc."]
```

The `#to_hash` helper method, which collapses all provided `DisplayData` into a single hash, can be used as a quick way to check the overall structure:

```ruby
> CocinaDisplay::DisplayData.to_hash(record.subject_display_data)
=> {"Marque"=>["Bugatti"], "Model"=>["Bugatti T51A"], "Subject"=>["Bugatti automobile"]}
```

Note that usage of the `displayLabel` attribute in Cocina overrides the `label` that would ordinarily be used to group an item. If some items in a field have a `displayLabel` and others do not, each unique `displayLabel` will get its own `DisplayData` object, because those items will be grouped under a separate heading. If you call a method like `#subject_display_data`, it's always possible that you will get some items grouped under the default label "Subject" as well as others grouped under custom labels.

#### Creating display data

In some cases, you may wish to create `DisplayData` for some data that isn't immediately available via a `_display_data` method. Depending on what you have, there are several helper methods available to do this that will label and group the data for you.

If the data you have is an array of objects that respond to `#label` and `#to_s`, you can use `DisplayData.from_objects`, which will automatically group the objects by their `label` and set the `values` to the result of calling `#to_s` on each object. Most of the objects returned by `CocinaRecord` methods, like `Contributor` and `Subject`, respond to these methods, and also handle nested `structuredValue`s in the Cocina when rendering to string. Handling of `parallelValue`s is also included for some object types like `Name` and `Title`.

```ruby
# This is actually equivalent to record.contributor_display_data!
> CocinaDisplay::DisplayData.from_objects(record.contributors)
```

If the data you have is a simple array of strings, you can use `DisplayData.from_strings`. You need to provide a `label` to group the strings under:

```ruby
> CocinaDisplay::DisplayData.from_strings(["Bugatti", "Bugatti T51A", "Bugatti automobile"], label: "Subject")
```

If the data you have is a hash from parsed Cocina JSON, you can use `DisplayData.from_cocina`. This will respect any `displayLabel` attributes in the provided Cocina. You can optionally provide a `label` to use if the Cocina did not contain a `displayLabel` attribute:

```ruby
> cocina = { 'value' => 'Bugatti', 'displayLabel' => 'Marque' }
# Will create a DisplayData with label "Marque" and value "Bugatti"
> CocinaDisplay::DisplayData.from_cocina(cocina)
# The same, but if the Cocina did not contain a displayLabel, it would use "Brand" instead
> CocinaDisplay::DisplayData.from_cocina(cocina, label: 'Brand')
```

Note that `DisplayData.from_cocina` does not handle `structuredValue`s or `parallelValue`s in the provided Cocina. Because the correct handling is dependent on the type of data, you're usually better off selecting the appropriate objects from the `CocinaRecord` and using `DisplayData.from_objects` instead. To find out more about the various objects returned by `CocinaRecord` methods, see the [API Documentation](https://sul-dlss.github.io/cocina_display/).

#### Custom formatting

In some cases, you may need more control over the formatting. The `DisplayData#objects` method gives access to the underlying objects that were grouped under a particular `label`, allowing you to format them as needed.

For contributors, the underlying objects are `Contributor` instances, which provide access to the associated `Name` and `Role` objects, as well as some other useful methods like `#forename` and `#organization?`:

```ruby
> record.contributor_display_data.first.label
=> "Former owner"
# All of the Contributors grouped under "Former owner"
> former_owners = record.contributor_display_data.first.objects
=> 
[#<CocinaDisplay::Contributors::Contributor:0x0000000123ad6550
...
> former_owners.first.names.first.to_s
=> "Hearst Magazines, Inc."
> former_owners.first.organization?
=> true
```

To review all the methods available on `Contributor`, see the [API Documentation](https://sul-dlss.github.io/cocina_display/CocinaDisplay/Contributors/Contributor.html).

### Searching for records

Sometimes you need to determine if records exist "in the wild" that exhibit particular characteristics in the Cocina metadata, like the presence or absence of a field, or a specific value in a field. There is a template script in the `scripts/` directory that can be used to crawl all DRUIDs released to a particular target, like Searchworks, and examine each record.

Another approach is to examine the records in the `/stacks` share using jq. For example:

```shell
find /stacks -name cocina.json | head -10000 |
  xargs jq '.description.subject[] | select(.source.uri=="http://id.loc.gov/authorities/subjects/") | select(.value != null) | select(.value | contains("--")) | .value'
```

### Logging of errors

You may create a custom error handler by implementing the `Honeybadger` interface (or just using Honeybadger) and assigning it to the `CocinaRecord.notifier`.

For example:

```ruby
Rails.application.config.to_prepare do
  CocinaDisplay.notifier = Honeybadger
end
```

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
