#!/usr/bin/env ruby
$VERBOSE = true

require 'cgi'

cgi = CGI.new
cgi.print cgi.header

# Generate enough content that the OS needs to flush
cgi.print "Flush me\n" * 10000
