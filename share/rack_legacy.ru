require 'rack/showexceptions'
require 'rack-legacy'

use Rack::ShowExceptions
use Rack::Legacy::Php
use Rack::Legacy::Cgi
run Rack::File.new Dir.getwd
