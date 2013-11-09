require 'test/unit'
require 'flexmock/test_unit'
require 'rack/legacy'
require 'rack/legacy/cgi'

class CgiTest < Test::Unit::TestCase

  def test_valid?
    assert app.valid?('success.cgi') # Valid file
    assert !app.valid?('../unit/cgi_test.rb') # Valid file but outside public
    assert !app.valid?('missing.cgi') # File not found
    assert !app.valid?('./') # Directory
  end

  def test_call
    assert_equal \
      [200, {"Content-Type"=>"text/html", "Content-Length"=>"7"}, ['Success']],
      app.call({'PATH_INFO' => 'success.cgi', 'REQUEST_METHOD' => 'GET'})
    assert_equal \
      [200, {"Content-Type"=>"text/html"}, 'Endpoint'],
      app.call({'PATH_INFO' => 'missing.cgi'})
    assert_equal [200, {}, ['']],
      app.call({'PATH_INFO' => 'empty.cgi', 'REQUEST_METHOD' => 'GET'})
    assert_equal [404, {"Content-Type"=>"text/html"}, ['']],
      app.call({'PATH_INFO' => '404.cgi', 'REQUEST_METHOD' => 'GET'})
    assert_equal [200, {"Content-Type"=>"text/html", 'Set-Cookie' => "cookie1\ncookie2"}, ['']],
      app.call({'PATH_INFO' => 'dup_headers.cgi', 'REQUEST_METHOD' => 'GET'})

    assert_raises Rack::Legacy::ExecutionError do
      $stderr.reopen open('/dev/null', 'w')
      app.call({'PATH_INFO' => 'error.cgi', 'REQUEST_METHOD' => 'GET'})
      $stderr.reopen STDERR
    end

    assert_raises Rack::Legacy::ExecutionError do
      $stderr.reopen open('/dev/null', 'w')
      app.call({'PATH_INFO' => 'syntax_error.cgi', 'REQUEST_METHOD' => 'GET'})
      $stderr.reopen STDERR
    end

    assert_equal \
      [200, {"Content-Type"=>"text/html", "Content-Length"=>"5"}, ['query']],
      app.call({
        'PATH_INFO' => 'param.cgi',
        'QUERY_STRING' => 'q=query',
        'REQUEST_METHOD' => 'GET'
      })
    assert_equal \
      [200, {"Content-Type"=>"text/html", "Content-Length"=>"4"}, ['post']],
      app.call({
        'PATH_INFO' => 'param.cgi',
        'REQUEST_METHOD' => 'POST',
        'CONTENT_LENGTH' => '6',
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
        'rack.input' => StringIO.new('q=post')
      })

    # NOTE: Not testing multipart forms (and with files) as the functional
    # tests will test that and trying to manually encode data would
    # increase the complexity of the test code more than it was worth.
  end

  def test_environment
    status, headers, body = *app.call({'PATH_INFO' => 'env.cgi', 'REQUEST_METHOD' => 'GET'})
    env = eval(body[0])
    assert File.join(File.dirname(__FILE__), '../fixtures'), env['DOCUMENT_ROOT']
    assert 'Rack Legacy', env['SERVER_SOFTWARE']
  end

  private

  def app
    Rack::Legacy::Cgi.new \
      proc {[200, {'Content-Type' => 'text/html'}, 'Endpoint']},
      File.join(File.dirname(__FILE__), '../fixtures')
  end

end
