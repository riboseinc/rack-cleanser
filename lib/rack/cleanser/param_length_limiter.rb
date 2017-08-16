# (c) Copyright 2017 Ribose Inc.
#

# URL:
# https://content.pivotal.io/blog/sanitizing-post-params-with-custom-rack-middleware
#
module Rack
  class Cleanser
    class RequestTooLargeException < RuntimeError; end

    class ParamLengthLimiter
      def initialize(name, options, block)
        @name               = name
        @default_max_length = options[:default] || 2048
        @block              = block
      end

      attr_reader :env

      def filter_exceptions
        env["CONTENT_TYPE"] !~ %r{\Amultipart/form-data.*boundary=\"?([^\";,]+)\"?}n
      end

      # 2048 is arbitrary
      # In characters.
      def max_length
        result = @block.call(env)

        if result.is_a? Integer
          result
        else
          @default_max_length
        end
      end

      def check_val(val)
        case val
        when String then
          if val.length > max_length
            warn "\e[1mLength is over #{max_length}! (#{val.length})\e[0m"
            raise RequestTooLargeException, "#{val.length} >= #{max_length}"
          end
        end
      end

      def scrub!
        rack_input = env["rack.input"].read
        params = Rack::Utils.parse_query(rack_input, "&") if filter_exceptions

        traverse_hash(params) do |val|
          check_val(val)
        end
      rescue => e
        warn "\e[1mv: Error raised from ParamLengthLimiter Middleware\e[0m:"
        warn e.message
        warn e.backtrace
        warn "\e[1m^: Error raised from ParamLengthLimiter Middleware\e[0m:"
      ensure
        env["rack.input"].rewind
      end

      # Recursively traverse values of given Hash with given block.
      def traverse_hash(hash_or_not, &blk)
        case hash_or_not
        when Hash then
          hash_or_not.each_pair do |_k, v|
            traverse_hash(v, &blk)
          end
        else yield hash_or_not
        end
      end

      def [](env)
        @env = env
        scrub!
      end
    end
  end
end
