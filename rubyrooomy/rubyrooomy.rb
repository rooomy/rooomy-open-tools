#!/usr/bin/env ruby

# Notice: Not to be published before
# LICENSE is in place

require "rubyment"


# Main class, basically a namespace
# for RubyRooomy (not a module for
# making serialization easier if ever
# needed).
# Inherits from Rubyment to
# benefit from the RubyGem functions
#  support.
class RubyRooomy < Rubyment
end


(__FILE__ == $0) && RubyRooomy.new({:invoke => ARGV})


