require 'rack/legacy/cgi'
require 'rack/legacy/php'

use Rack::Legacy::Php, Dir.getwd
use Rack::Legacy::Cgi, Dir.getwd
run Rack::File.new Dir.getwd