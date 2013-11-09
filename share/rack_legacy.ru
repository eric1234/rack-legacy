require 'rack/showexceptions'
require 'rack-legacy'

use Rack::ShowExceptions
use Rack::Legacy::Php, Dir.getwd
use Rack::Legacy::Cgi, Dir.getwd
run Rack::File.new Dir.getwd
