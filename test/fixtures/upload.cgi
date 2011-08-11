#!/usr/bin/env ruby
$VERBOSE = true

require 'cgi'
cgi = CGI.new

file = cgi.params['test'].first

cgi.print cgi.header
cgi.print "Filename: #{file.original_filename}\n"
cgi.print "Size: #{file.length}\n"
cgi.print "Contents: #{file.read}"
