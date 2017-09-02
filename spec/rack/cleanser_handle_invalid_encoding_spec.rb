require "spec_helper"

RSpec.describe "Handling invalid encoding" do
  before { Rack::Cleanser.filter_bad_uri_encoding }

  let(:mock_request) { Rack::MockRequest.new(app) }
  let(:http_methods) { %w[POST GET] }

  it "passes requests which has minimal header set and no parameters through" do
    http_methods.each do |http_m|
      response = make_request method: http_m, headers: {}
      expect(response).to be_coming_from_inner_app
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
        response = make_request method: http_m, headers: { header_name => good }
        expect(inner_app).to have_been_called_with_headers(
          "REQUEST_METHOD" => http_m, header_name => good,
        )
        expect(response).to be_coming_from_inner_app

        response = make_request method: http_m, headers: { header_name => bad }
        expect(inner_app).to have_been_called_with_headers(
          "REQUEST_METHOD" => http_m, header_name => bad_fixed,
        )
        expect(response).to be_coming_from_inner_app
      end
    end

    it "returns HTTP 404 if #{header_name} contains percent-encoded byte " \
       "sequences which are invalid in UTF-8" do

      # %c5 and %82 are valid hex representations, and in this sequence they
      # stand for Polish "ł" character in UTF-8.  Neither %c5 nor %82 are valid
      # when alone
      good = "wspania%c5%82y"
      bad = "wspania%c5y"

      http_methods.each do |http_m|
        response = make_request method: http_m, headers: { header_name => good }
        expect(inner_app).to have_been_called_with_headers(
          "REQUEST_METHOD" => http_m, header_name => good,
        )
        expect(response).to be_coming_from_inner_app

        expect { make_request method: http_m, headers: { header_name => bad } }.
          to raise_exception(ActionController::RoutingError)
      end
    end
  end

  def make_request(method:, path: "/", headers: {})
    mock_request.request method, path, headers
  end

  def be_coming_from_inner_app
    satisfy { |r| r.status == 200 && r.body == "Hello World" }
  end

  def have_been_called_with_headers(headers)
    have_received(:call).with(hash_including(headers))
  end
end
