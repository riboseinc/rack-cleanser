RSpec::Matchers.define :be_coming_from_inner_app do
  match do |response|
    response.status == 200 && response.body == "Hello World"
  end
end

RSpec::Matchers.define :be_an_error do |code|
  match do |response|
    # rubocop:disable Style/RescueModifier
    parsed_json = (JSON.parse(response.body) rescue {})
    # rubocop:enable Style/RescueModifier
    response.status == code && parsed_json.has_key?("error_message")
  end
end

# RSpec::Mocks matchers cannot be defined that easily.
module CustomMatchers
  def have_been_called_with_headers(headers)
    have_received(:call).with(hash_including(headers))
  end
end

RSpec.configure do |c|
  c.include CustomMatchers
end
