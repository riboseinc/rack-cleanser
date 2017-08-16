require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include Rack::Test::Methods

  config.after { Rack::Cleanser.clear! }

  def app
    Rack::Builder.new do
      use Rack::Cleanser
      run lambda { |_env| [200, {}, ["Hello World"]] }
    end.to_app
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
