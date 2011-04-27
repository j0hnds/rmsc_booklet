#!/usr/bin/env ruby
# I don't this this particular script has a whole lot of value. Unless
# of course, you want to output the first two arguments on the command
# line, then output the entire command line twice.
#
# I, for one, think this is awesome.
#
puts "$0 - #{$0}"
puts "$1 - #{$1}"
puts "ARGV - #{ARGV}"
p ARGV
