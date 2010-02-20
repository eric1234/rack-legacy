#!/usr/bin/env ruby
$VERBOSE = true

require 'cgi'

$stderr.puts 'Standard Error'
cgi = CGI.new
cgi.out('foo' => 'bar') {'Standard Out'}
exit 1
