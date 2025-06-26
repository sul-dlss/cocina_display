# frozen_string_literal: true

# These have to come before importing any other code for coverage to work!
require "simplecov"
require "simplecov-rspec"

# Ignore coverage if running a single file; otherwise turn it on
if RSpec.configuration.files_to_run.count > 1
  SimpleCov.start do
    add_filter "/spec/"
  end
  SimpleCov::RSpec.start(list_uncovered_lines: true)
end

require "cocina_display"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# This method is normally provided by ActiveSupport, but easy enough to define
# on our own and save a dependency
def file_fixture(filename)
  File.join(File.dirname(__FILE__), "fixtures", filename)
end
