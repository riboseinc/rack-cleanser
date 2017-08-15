# (c) Copyright 2017 Ribose Inc.
#

require 'rack'
require 'rack/cleanser/version'
require 'forwardable'
require 'json'
require 'pp'

module Rack
  class Cleanser

    autoload :ParamLengthLimiter, 'rack/cleanser/param_length_limiter'
    autoload :InvalidURIEncoding, 'rack/cleanser/invalid_uri_encoding'

    class << self

      attr_accessor :oversize_response

      def limit_param_length(name, options = {}, &block)
        param_length_limits[name] = ParamLengthLimiter.new(name, options, block)
      end

      def filter_bad_uri_encoding
        @want_uri_encoding_filtering = true
      end

      def param_length_limits
        @param_length_limits ||= {}
      end

      def filter_bad_uri_encoding!(env)
        InvalidURIEncoding.new[env] if @want_uri_encoding_filtering
      end

      def limit_param_length!(env)
        param_length_limits.each do |_name, limit|
          limit[env]
        end
      end

      def clear!
        @want_uri_encoding_filtering = false
        @param_length_limits         = {}
      end

      def cleanse!(env)
        limit_param_length!(env)
        filter_bad_uri_encoding!(env)
      end
    end

    def initialize(app)
      @app = app
    end

    @oversize_response = lambda { |_env, exn|
      [
        413,
        { 'Content-Type' => 'application/json' },
        [{
          error_message: "Request entity too large, #{exn.message}"
        }.to_json]
      ]
    }

    def call(env)
      cleanse!(env)
      @app.call(env)
    rescue RequestTooLargeException => e
      self.class.oversize_response.call(env, e)
    end

    extend Forwardable
    def_delegators self,
                   :cleanse!
  end
end
