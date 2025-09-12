# frozen_string_literal: true

# These have to come before importing any other code for coverage to work!
require "rspec"
require "simplecov"
require "simplecov-rspec"
require "debug"

# Ignore coverage if running a single file; otherwise turn it on
if RSpec.configuration.files_to_run.count > 1
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "lib/cocina_display.rb"
  end
  SimpleCov::RSpec.start(list_uncovered_lines: true)
end

require "cocina_display"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.max_formatted_output_length = nil  # Show full diffs
  end
end

# This method is normally provided by ActiveSupport, but easy enough to define
# on our own and save a dependency
def file_fixture(filename)
  File.join(File.dirname(__FILE__), "fixtures", filename)
end
