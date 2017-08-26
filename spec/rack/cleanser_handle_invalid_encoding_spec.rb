require "spec_helper"

RSpec.describe "Handling invalid encoding" do
  before { Rack::Cleanser.filter_bad_uri_encoding }

  let(:mock_request) { Rack::MockRequest.new(app) }
  let(:http_methods) { %w[POST GET] }

  it "passes requests which has minimal header set and no parameters through" do
    http_methods.each do |http_m|
      response = mock_request.request http_m, "/", {}
      expect(response.status).to eq(200)
      expect(response.body).to eq("Hello World")
    end
  end

  %w[
    HTTP_REFERER
    PATH_INFO
    QUERY_STRING
    REQUEST_PATH
    REQUEST_URI
    HTTP_X_FORWARDED_HOST
  ].each do |header_name|
    it "sanitizes #{header_name} header by percent-encoding lone percent "\
       "signs" do
      # %c5 and %82 are valid hex representations, and in this sequence they
      # stand for Polish "ł" character in UTF-8
      good = "wspania%c5%82y"
      # neither %tt, %-b, nor %d are valid hex representations
      bad = "pre%tty%-ba%d"
      # lone percent signs should be replaced with %25
      bad_fixed = "pre%25tty%25-ba%25d"

      http_methods.each do |http_m|
        response = mock_request.request http_m, "/", { header_name => good }
        expect(inner_app).to have_received(:call).with(
          hash_including("REQUEST_METHOD" => http_m, header_name => good),
        )
        expect(response.status).to eq(200)
        expect(response.body).to eq("Hello World")

        response = mock_request.request http_m, "/", { header_name => bad }
        expect(inner_app).to have_received(:call).with(
          hash_including("REQUEST_METHOD" => http_m, header_name => bad_fixed),
        )
        expect(response.status).to eq(200)
        expect(response.body).to eq("Hello World")
      end
    end
  end
end
