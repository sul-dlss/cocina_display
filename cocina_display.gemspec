# frozen_string_literal: true

require_relative "lib/cocina_display/version"

Gem::Specification.new do |spec|
  spec.name = "cocina_display"
  spec.version = CocinaDisplay::VERSION
  spec.authors = ["Nick Budak"]
  spec.email = ["budak@stanford.edu"]

  spec.summary = "Helpers for rendering Cocina metadata"
  spec.homepage = "https://sul-dlss.github.io/cocina_display/"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sul-dlss/cocina_display"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "janeway-jsonpath", "~> 0.6" # for nested JSON queries
  spec.add_dependency "activesupport", "~> 8.0", ">= 8.0.2" # for helpers like present?

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "simplecov", "~> 0.22.0"
  spec.add_development_dependency "simplecov-rspec", "~> 0.4"
  spec.add_development_dependency "yard", "~> 0.9.37"
  spec.add_development_dependency "webrick", "~> 1.9", ">= 1.9.1" # for yard server
end
