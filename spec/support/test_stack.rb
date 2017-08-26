RSpec.shared_context "test stack" do
  let(:inner_app) do
    lambda { |_env| [200, {}, ["Hello World"]] }
  end

  let(:app) do
    builder = Rack::Builder.new
    builder.use Rack::Cleanser
    builder.run inner_app
    builder.to_app
  end
end
