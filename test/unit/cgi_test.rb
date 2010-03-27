require 'test/unit'

require 'rubygems'
require 'flexmock/test_unit'

require 'rack/legacy/cgi'

class CgiTest < Test::Unit::TestCase

  def test_valid?
    assert app.valid?('success.cgi') # Valid file
    assert !app.valid?('../unit/cgi_test.rb') # Valid file but outside public
    assert !app.valid?('missing.cgi') # File not found
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
    status, headers, body = app.call({'PATH_INFO' => 'error.cgi', 'REQUEST_METHOD' => 'GET'})
    assert_equal 500, status
    assert_equal({"Content-Type"=>"text/html"}, headers)
    assert_match /Internal Server Error/, body.first      

    status, headers, body = app.call({'PATH_INFO' => 'syntax_error.cgi', 'REQUEST_METHOD' => 'GET'})
    assert_equal 500, status
    assert_equal({"Content-Type"=>"text/html"}, headers)
    assert_match /Internal Server Error/, body.first

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

  # Is the correct parts of the program captured (i.e. STDOUT, STDERR,
  # headers, etc.) for the purposes of error reporting.
  def test_error_capture
    app.call({'PATH_INFO' => 'capture.cgi', 'REQUEST_METHOD' => 'GET'})
    mock = flexmock Rack::Legacy::ErrorPage
    mock.should_receive(:new).with(Hash,
      {'Content-Type' => 'text/html', 'Content-Length' => 12, 'foo' => 'bar'},
      'Standard Out', 'Standard Error')
  end

  private

  def app
    Rack::Legacy::Cgi.new \
      proc {[200, {'Content-Type' => 'text/html'}, 'Endpoint']},
      File.join(File.dirname(__FILE__), '../fixtures')
  end

end