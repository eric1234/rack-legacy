#!/usr/bin/env ruby
$VERBOSE = true

require 'cgi'

cgi = CGI.new
cgi.out {cgi.params['q']}
