# (c) Copyright 2017 Ribose Inc.
#

module Rack
  class Cleanser
    module Regexps
      CONTENT_TYPE_MULTIPART_FORM =
        %r{\Amultipart/form-data.*boundary=\"?([^\";,]+)\"?}n

      # A percent sign character which is not followed by two hex digits
      LONE_PERCENT_SIGN = /%(?![0-9a-fA-F]{2})/
    end
  end
end
