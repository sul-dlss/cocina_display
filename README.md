# CocinaDisplay

[![Build Status](https://github.com/sul-dlss/cocina_display/workflows/CI/badge.svg)](https://github.com/sul-dlss/cocina_display/actions)
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

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Background

Historically, applications at SUL used a combination of several gems to render objects represented by MODS XML. With the transition to the Cocina data model, infrastructure applications adopted the [`cocina-models` gem](https://github.com/sul-dlss/cocina-models), which provides accessor objects and validators over Cocina JSON. Internal applications can obtain such objects over HTTP using [`dor-services-client`](https://github.com/sul-dlss/dor-services-client).

On the access side, Cocina JSON is available statically via [PURL](https://purl.stanford.edu), but is only updated when an object is published ("shelved") from SDR. This frequently results in data that is technically invalid with respect to `cocina-models` but is still valid in the context of a patron-facing application. Rather than tightly coupling access applications to `cocina-models`, this gem provides a set of helpers designed to safely parse Cocina JSON and render it in a consistent way across applications.

The intent is that both applications that directly render SDR metadata as HTML (PURL, Exhibits) and applications that index it for later display in a catalog (Searchworks, Earthworks, Dataworks) can adopt a single gem for rendering Cocina in a human-readable way. This gem **does not** aim to render HTML or provide view components – that is the responsibility of the consuming application. It **does** provide macros for those applications using Traject to index metadata.
