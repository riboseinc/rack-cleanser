require "spec_helper"

RSpec.describe Rack::Cleanser do
  it "has a version number" do
    expect(described_class::VERSION).to be_a(String)
  end
end
