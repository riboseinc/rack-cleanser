# (c) Copyright 2017 Ribose Inc.
#

# This is a middleware to check for invalid user's request path and request
# parameters.
module Rack
  class Cleanser
    class InvalidURIEncoding
      include Regexps

      # General Checking for user's input params
      # throw 404 if params contain abnormal input
      def check_encoding(query)
        # make sure all params have valid encoding
        all_values_for_hash(query).each do |param|
          if param.respond_to?(:valid_encoding?) && !param.valid_encoding?
            return :bad_encoding
          end
        end
      end

      def check_nested(query)
        Rack::Utils.parse_nested_query(query)
      rescue
        :bad_query
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
          if LONE_PERCENT_SIGN.match?(env[key].to_s)
            env[key] = env[key].gsub(LONE_PERCENT_SIGN, "%25")
          end
          raise_404_error if check_nested(env[key]) == :bad_query
        end

        # use these methods to get params as there is conflict with openresty
        # request_params = Rack::Request.new(env).params
        post_params = {}

        post_params = if (env["CONTENT_TYPE"] || "").match?(CONTENT_TYPE_MULTIPART_FORM)
                        {}
                      else
                        Rack::Utils.parse_query(env["rack.input"].read, "&")
                      end

        get_params = Rack::Utils.parse_query(env["QUERY_STRING"], "&")
        request_params = {}.merge(get_params).merge(post_params)

        # Because env['rack.input'] is String IO object, so we need to rewind
        # that to ensure it can be read again by others.
        env["rack.input"].rewind

        raise_404_error if check_encoding(request_params) == :bad_encoding

        # make sure the authenticity token is a string
        request_params.keys.each do |key|
          raise_404_error if key.match?(HEADER_AUTH_TOKEN)
        end
      end

      def raise_404_error
        raise ActionController::RoutingError.new("Not Found")
      end
    end
  end
end
