require 'test/unit'

require 'rubygems'
require 'httparty'

require 'rack/legacy/cgi'

class CgiTest < Test::Unit::TestCase

  def test_valid?
    assert app.valid?('success.cgi')
    assert !app.valid?('../cgi_test.rb')
    assert !app.valid?('../missing.cgi')
  end

  def test_call
    assert_equal \
      [200, {"Content-Type"=>"text/html", "Content-Length"=>"7"}, 'Success'],
      app.call({'PATH_INFO' => 'success.cgi', 'REQUEST_METHOD' => 'GET'})
    assert_equal \
      [200, {"Content-Type"=>"text/html"}, 'Endpoint'],
      app.call({'PATH_INFO' => 'missing.cgi'})
    assert_equal [200, {}, ''],
      app.call({'PATH_INFO' => 'empty.cgi', 'REQUEST_METHOD' => 'GET'})
    assert_equal [500, {"Content-Type"=>"text/plain"}, 'Error'],
      app.call({'PATH_INFO' => 'error.cgi', 'REQUEST_METHOD' => 'GET'})

    # Redirect stderr to keep tests clean
    STDERR.reopen(File.new('/dev/null'))
    assert_equal [500, {"Content-Type"=>"text/plain"}, 'Error'],
      app.call({'PATH_INFO' => 'syntax_error.cgi', 'REQUEST_METHOD' => 'GET'})
    STDERR.reopen(File.for_fd(2))

    assert_equal \
      [200, {"Content-Type"=>"text/html", "Content-Length"=>"1"}, 'query'],
      app.call({
        'PATH_INFO' => 'param.cgi',
        'QUERY_STRING' => 'q=query',
        'REQUEST_METHOD' => 'GET'
      })
    assert_equal \
      [200, {"Content-Type"=>"text/html", "Content-Length"=>"1"}, 'post'],
      app.call({
        'PATH_INFO' => 'param.cgi',
        'REQUEST_METHOD' => 'POST',
        'CONTENT_LENGTH' => '6',
        'rack.input' => StringIO.new('q=post')
      })
  end
  
  private

  def app
    Rack::Legacy::Cgi.new \
      proc {[200, {'Content-Type' => 'text/html'}, 'Endpoint']},
      File.join(File.dirname(__FILE__), '../fixtures')
  end

end