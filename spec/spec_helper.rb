# frozen_string_literal: true

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
