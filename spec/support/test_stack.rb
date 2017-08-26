RSpec.shared_context "test stack" do
  let(:inner_app) do
    double.tap do |dbl|
      ok = [200, {}, ["Hello World"]]
      allow(dbl).to receive(:call).with(kind_of(Hash)).and_return(ok)
    end
  end

  let(:app) do
    builder = Rack::Builder.new
    builder.use Rack::Cleanser
    builder.run inner_app
    builder.to_app
  end
end
