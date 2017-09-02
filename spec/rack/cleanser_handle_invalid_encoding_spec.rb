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

        response = make_request method: http_m, headers: { header_name => bad }
        expect(response).to be_an_error(404)
      end
    end

    it "returns HTTP 404 when form-encoded parameters in POST requests " \
       "contain percent-encoded byte sequences which are invalid in UTF-8" do
      good = "some_control=wspania%c5%82y"
      bad = "some_control=wspania%c5y"
      headers = { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }

      response = make_request method: "POST", body: good, headers: headers
      expect(response).to be_coming_from_inner_app

      response = make_request method: "POST", body: bad, headers: headers
      expect(response).to be_an_error(404)
    end

    it "allows any characters in parameters which are sent in message body " \
       "of multipart POST request" do

      headers = { "CONTENT_TYPE" => "multipart/form-data; boundary=boundary" }

      good = <<~FORM
        --boundary
        Content-Disposition: form-data; name="good_value"

        wspania%c5%82y
        --boundary
        Content-Disposition: form-data; name="also_good"

        wspania%c5y
        --boundary
        Content-Disposition: form-data; name="also_good_2"

        wspania\xc5\x82y
        --boundary
        Content-Disposition: form-data; name="also_good_3"

        wspania\xc5y
        --boundary--
      FORM

      response = make_request method: "POST", body: good, headers: headers
      expect(response).to be_coming_from_inner_app
    end
  end

  def make_request(method:, path: "/", headers: {}, body: nil)
    env = body ? headers.merge(input: body) : headers
    mock_request.request method, path, env
  end
end
