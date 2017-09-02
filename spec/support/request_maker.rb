RSpec.shared_context "request maker", with_request_maker: true do
  # Custom way to mock Rack requests.  Contrary to Rack::Test, it allows to
  # make incorrect requests with ease.  And this is very useful in this test
  # suite as the tested gem is expected to filter out such requests.
  def make_request(method:, path: "/", headers: {}, body: nil)
    env = body ? headers.merge(input: body) : headers
    mock_request.request method, path, env
  end
end
