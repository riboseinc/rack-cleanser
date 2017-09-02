module CustomMatchers
  def be_coming_from_inner_app
    satisfy { |r| r.status == 200 && r.body == "Hello World" }
  end

  def be_an_error(code)
    satisfy do |r|
      # rubocop:disable Style/RescueModifier
      parsed_json = (JSON.parse(r.body) rescue {})
      # rubocop:enable Style/RescueModifier
      r.status == code && parsed_json.has_key?("error_message")
    end
  end

  def have_been_called_with_headers(headers)
    have_received(:call).with(hash_including(headers))
  end
end

RSpec.configure do |c|
  c.include CustomMatchers
end
