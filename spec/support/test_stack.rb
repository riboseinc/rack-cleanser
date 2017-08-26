RSpec.shared_context "test stack" do
  def app
    Rack::Builder.new do
      use Rack::Cleanser
      run lambda { |_env| [200, {}, ["Hello World"]] }
    end.to_app
  end
end
