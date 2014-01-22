require 'minitest/autorun'
require 'rack/legacy'
require 'rack/legacy/php'

class PhpTest < MiniTest::Unit::TestCase

  def test_valid?
    assert app.valid?('success.php') # Valid file
    assert app.valid?('/success.php') # Valid file
    assert !app.valid?('missing.php') # File not found
    assert !app.valid?('./') # Directory
    assert !app.valid?('success.cgi') # Valid file but not a php file
  end

  def test_call
    response = app.call 'PATH_INFO' => 'success.php', 'REQUEST_METHOD' => 'GET'
    assert_equal '200', response.first
    assert_equal ['Success'], response.last
    assert_equal 'text/html', response[1]['Content-type'].first
    assert_match /^PHP/, response[1]['X-Powered-By'].first

    response = app.call 'PATH_INFO' => '/', 'REQUEST_METHOD' => 'GET'
    assert_equal '200', response.first
    assert_equal ['PHP index'], response.last
    assert_equal 'text/html', response[1]['Content-type'].first
    assert_match /^PHP/, response[1]['X-Powered-By'].first

    assert_equal \
      [200, {"Content-Type"=>"text/html"}, ['Endpoint']],
      app.call({'PATH_INFO' => 'missing.php'})

    response = app.call 'PATH_INFO' => 'empty.php', 'REQUEST_METHOD' => 'GET'
    assert_equal '200', response.first
    assert_equal [''], response.last
    assert_equal 'text/html', response[1]['Content-type'].first
    assert_match /^PHP/, response[1]['X-Powered-By'].first

    response = app.call({'PATH_INFO' => 'syntax_error.php', 'REQUEST_METHOD' => 'GET'})
    assert_equal '500', response.first
    assert_equal [''], response.last
    assert_equal 'text/html', response[1]['Content-type'].first
    assert_match /^PHP/, response[1]['X-Powered-By'].first

    response = app.call({
      'PATH_INFO' => 'querystring.php',
      'QUERY_STRING' => 'q=query',
      'REQUEST_METHOD' => 'GET'
    })
    assert_equal '200', response.first
    assert_equal ['query'], response.last
    assert_equal 'text/html', response[1]['Content-type'].first
    assert_match /^PHP/, response[1]['X-Powered-By'].first

    response = app.call({
      'PATH_INFO' => 'post.php',
      'REQUEST_METHOD' => 'POST',
      'CONTENT_LENGTH' => '6',
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
      'rack.input' => StringIO.new('q=post')
    })
    assert_equal '200', response.first
    assert_equal ['post'], response.last
    assert_equal 'text/html', response[1]['Content-type'].first
    assert_match /^PHP/, response[1]['X-Powered-By'].first
  end

  def test_environment
    status, headers, body = *app.call({
      'PATH_INFO' => 'env.php/foo',
      'QUERY_STRING' => 'bar=baz',
      'REQUEST_METHOD' => 'GET',
    })
    env = Hash[body[0].scan(/\[([^\]]+)\]\s+=>\s+(.+)/)]
    assert File.join(File.dirname(__FILE__), '../fixtures'), env['DOCUMENT_ROOT']
    assert File.join(File.dirname(__FILE__), '../fixtures', 'env.php'), env['SCRIPT_FILENAME']
    assert 'env.php', env['SCRIPT_NAME']
    assert '/foo', env['PATH_INFO']
    assert 'env.php/foo?bar=baz', env['REQUEST_URI']
    assert 'Rack Legacy', env['SERVER_SOFTWARE']
  end

  private

  def self.app
    return @app if @app
    @app = Rack::Legacy::Php.new \
      proc {[200, {'Content-Type' => 'text/html'}, ['Endpoint']]},
      File.join(File.dirname(__FILE__), '../fixtures'), 'php', 8180, true
    sleep 2 # Wait for it to boot
    @app
  end
  def app; self.class.app end

end
