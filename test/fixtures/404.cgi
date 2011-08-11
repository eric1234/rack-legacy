#!/usr/bin/env ruby
$VERBOSE = true

require 'cgi'

cgi = CGI.new
cgi.print cgi.header('status' => 'NOT_FOUND')
