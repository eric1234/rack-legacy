#!/usr/bin/env ruby
$VERBOSE = true

require 'cgi'

cgi = CGI.new
cgi.print cgi.header('cookie' => ['cookie1', 'cookie2'])
