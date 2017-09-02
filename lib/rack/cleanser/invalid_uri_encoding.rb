# (c) Copyright 2017 Ribose Inc.
#

# This is a middleware to check for invalid user's request path and request
# parameters.
module Rack
  class Cleanser
    class InvalidURIEncoding
      include Regexps

      # Escapes lone percent signs, that is percent sign characters which are
      # not followed by two hex digits
      def fix_lone_percent_signs(string_to_fix)
        if LONE_PERCENT_SIGN =~ string_to_fix.to_s
          string_to_fix.gsub!(LONE_PERCENT_SIGN, "%25")
        end
      end

      # General Checking for user's input params
      # throw 404 if params contain abnormal input
      def check_encoding(query)
        # make sure all params have valid encoding
        all_values_for_hash(query).each do |param|
          if param.respond_to?(:valid_encoding?) && !param.valid_encoding?
            halt_with_404
          end
        end
      end

      def check_nested(query)
        Rack::Utils.parse_nested_query(query)
      rescue
        halt_with_404
      end

      # to get all values from a nested hash (i.e a hash contains hashes/arrays)
      # e.g. {:a => 1, :b => {:ba => 2, :bb => [3, 4]}} gives you [1, 2, 3, 4]
      def all_values_for_hash(hash)
        result = []
        hash.values.each do |hash_value|
          case hash_value
          when Hash
            result += all_values_for_hash(hash_value)
          when Array
            # convert the array to hash
            sub_hash = Hash[
              hash_value.flatten.map.with_index do |value, index|
                [index, value]
              end
            ]
            result += all_values_for_hash(sub_hash)
          else
            result << hash_value
          end
        end
        result
      end

      def [](env)
        # Check and clean up trailing % characters by replacing them with their
        # encoded equivalent %25
        %w[
          HTTP_REFERER
          PATH_INFO
          QUERY_STRING
          REQUEST_PATH
          REQUEST_URI
          HTTP_X_FORWARDED_HOST
        ].each do |key|
          fix_lone_percent_signs(env[key])
          check_nested(env[key])
        end

        # use these methods to get params as there is conflict with openresty
        # request_params = Rack::Request.new(env).params
        post_params = if (env["CONTENT_TYPE"] || "") =~ CONTENT_TYPE_MULTIPART_FORM
                        {}
                      else
                        Rack::Utils.parse_query(env["rack.input"].read, "&")
                      end

        get_params = Rack::Utils.parse_query(env["QUERY_STRING"], "&")
        request_params = {}.merge(get_params).merge(post_params)

        # Because env['rack.input'] is String IO object, so we need to rewind
        # that to ensure it can be read again by others.
        env["rack.input"].rewind

        check_encoding(request_params)

        # make sure the authenticity token is a string
        request_params.keys.each do |key|
          halt_with_404 if key =~ HEADER_AUTH_TOKEN
        end
      end

      def halt_with_404
        msg = "Page not found"
        Rack::Cleanser::halt_with_error(404, msg)
      end
    end
  end
end
