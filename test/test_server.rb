# The unit tests do full end-to-end testing therefore a real server
# needs to be run. Start this script before running the unit tests.

require 'rubygems'
require 'rack'
require 'rack/legacy/php'

app = Rack::Builder.app do
  use Rack::Legacy::Php, File.join(File.dirname(__FILE__), 'fixtures')
  run lambda {|env| [200, {'Content-Type' => 'text/html'}, 'Endpoint']}
end
Rack::Handler::WEBrick.run app, :Port => 4000