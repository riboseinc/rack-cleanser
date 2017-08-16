require "bundler/setup"
require "rack/cleanser"
require "rack/test"

require "action_dispatch"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include Rack::Test::Methods

  config.after { Rack::Cleanser.clear! }

  def app
    Rack::Builder.new {
      use Rack::Cleanser
      run lambda { |env| [200, {}, ["Hello World"]] }
    }.to_app
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
