require 'test/unit'

require 'rack/legacy/php'

class PhpTest < Test::Unit::TestCase

  def test_valid?
    # Same restrictions as parent class
    assert app.valid?('success.php') # Valid file
    assert !app.valid?('../unit/php_test.rb') # Valid file but outside public
    assert !app.valid?('missing.php') # File not found
    assert !app.valid?('../fixtures/invalid.php') # Directory

    # Some new tests that are specific to php
    assert !app.valid?('success.cgi') # Valid file but not a php file
  end

  def test_call
    response = app.call 'PATH_INFO' => 'success.php', 'REQUEST_METHOD' => 'GET'
    assert_equal 200, response.first
    assert_equal ['Success'], response.last
    assert_equal 'text/html', response[1]['Content-type']
    assert_not_nil response[1]['X-Powered-By']

    assert_equal \
      [200, {"Content-Type"=>"text/html"}, 'Endpoint'],
      app.call({'PATH_INFO' => 'missing.php'})

    response = app.call 'PATH_INFO' => 'empty.php', 'REQUEST_METHOD' => 'GET'
    assert_equal 200, response.first
    assert_equal [''], response.last
    assert_equal 'text/html', response[1]['Content-type']
    assert_match /^PHP/, response[1]['X-Powered-By']

    status, headers, body = app.call({'PATH_INFO' => 'error.php', 'REQUEST_METHOD' => 'GET'})
    assert_equal 500, status
    assert_equal({"Content-Type"=>"text/html"}, headers)
    assert_match /Internal Server Error/, body.first

    status, headers, body = app.call({'PATH_INFO' => 'syntax_error.php', 'REQUEST_METHOD' => 'GET'})
    assert_equal 500, status
    assert_equal({"Content-Type"=>"text/html"}, headers)
    assert_match /Internal Server Error/, body.first

    response = app.call({
      'PATH_INFO' => 'querystring.php',
      'QUERY_STRING' => 'q=query',
      'REQUEST_METHOD' => 'GET'
    })
    assert_equal 200, response.first
    assert_equal ['query'], response.last
    assert_equal 'text/html', response[1]['Content-type']
    assert_match /^PHP/, response[1]['X-Powered-By']

    response = app.call({
      'PATH_INFO' => 'post.php',
      'REQUEST_METHOD' => 'POST',
      'CONTENT_LENGTH' => '6',
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
      'rack.input' => StringIO.new('q=post')
    })
    assert_equal 200, response.first
    assert_equal ['post'], response.last
    assert_equal 'text/html', response[1]['Content-type']
    assert_match /^PHP/, response[1]['X-Powered-By']
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

  def test_parse_htaccess
    file = File.join(File.dirname(__FILE__), '../fixtures/dir1/dir2/.htaccess')
    assert_equal({
      'include_path'      => 'backend:ext:.',
      'auto_prepend_file' => 'backend/lib/setup.php',
      'auto_append_file'  => 'backend/lib/teardown.php',
      'output_buffering'  => 'off',
    }, Rack::Legacy::Php::HtAccess.new(file).to_hash)
  end

  def test_htaccess_search
    file = File.join(File.dirname(__FILE__), '../fixtures/dir1/dir2/test.php')
    root = File.join(File.dirname(__FILE__), '../fixtures')
    assert_equal [
      File.join(File.dirname(__FILE__), '../fixtures/.htaccess'),
      File.join(File.dirname(__FILE__), '../fixtures/dir1/dir2/.htaccess'),
    ], Rack::Legacy::Php::HtAccess.find_all(file, root).collect(&:file)
  end

  def test_merge_all
    file = File.join(File.dirname(__FILE__), '../fixtures/dir1/dir2/test.php')
    root = File.join(File.dirname(__FILE__), '../fixtures')
    assert_equal({
      'include_path'      => 'backend:ext:.',
      'auto_prepend_file' => 'backend/lib/setup.php',
      'auto_append_file'  => 'backend/lib/teardown.php',
      'output_buffering'  => 'off',
      'foo'               => 'bar',
      'baz'               => 'boo',
    }, Rack::Legacy::Php::HtAccess.merge_all(file, root))

    assert_equal({},
      Rack::Legacy::Php::HtAccess.merge_all(__FILE__, File.dirname(__FILE__)))
  end

  def test_htaccess_flag
    status, headers, body = *app.call({'PATH_INFO' => 'ini.php'})
    assert_equal '1', body[0]

    app = Rack::Legacy::Php.new \
      proc {[200, {'Content-Type' => 'text/html'}, 'Endpoint']},
      File.join(File.dirname(__FILE__), '../fixtures'), 'php-cgi', false
    status, headers, body = *app.call({'PATH_INFO' => 'ini.php'})
    assert_equal '4096', body[0]
  end

  private

  def app
    Rack::Legacy::Php.new \
      proc {[200, {'Content-Type' => 'text/html'}, 'Endpoint']},
      File.join(File.dirname(__FILE__), '../fixtures')
  end

end
