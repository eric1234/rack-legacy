require 'test/unit'

require 'rubygems'
require 'httparty'

require 'rack/legacy/php'

class PhpTest < Test::Unit::TestCase

  def test_valid?
    # Same restrictions as parent class
    assert app.valid?('success.php') # Valid file
    assert !app.valid?('../unit/php_test.rb') # Valid file but outside public
    assert !app.valid?('missing.php') # File not found

    # Some new tests that are specific to php
    assert !app.valid?('success.cgi') # Valid file but not a php file
  end

  def test_call
    response = app.call 'PATH_INFO' => 'success.php', 'REQUEST_METHOD' => 'GET'
    assert_equal 200, response.first
    assert_equal 'Success', response.last
    assert_equal 'text/html', response[1]['Content-type']
    assert_not_nil response[1]['X-Powered-By']

    assert_equal \
      [200, {"Content-Type"=>"text/html"}, 'Endpoint'],
      app.call({'PATH_INFO' => 'missing.php'})

    response = app.call 'PATH_INFO' => 'empty.php', 'REQUEST_METHOD' => 'GET'
    assert_equal 200, response.first
    assert_equal '', response.last
    assert_equal 'text/html', response[1]['Content-type']
    assert_match /^PHP/, response[1]['X-Powered-By']

    assert_equal [500, {"Content-Type"=>"text/plain"}, 'Error'],
      app.call({'PATH_INFO' => 'error.php', 'REQUEST_METHOD' => 'GET'})
    assert_equal [500, {"Content-Type"=>"text/plain"}, 'Error'],
      app.call({'PATH_INFO' => 'syntax_error.php', 'REQUEST_METHOD' => 'GET'})

    response = app.call({
      'PATH_INFO' => 'querystring.php',
      'QUERY_STRING' => 'q=query',
      'REQUEST_METHOD' => 'GET'
    })
    assert_equal 200, response.first
    assert_equal 'query', response.last
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
    assert_equal 'post', response.last
    assert_equal 'text/html', response[1]['Content-type']
    assert_match /^PHP/, response[1]['X-Powered-By']
  end
  
  private

  def app
    Rack::Legacy::Php.new \
      proc {[200, {'Content-Type' => 'text/html'}, 'Endpoint']},
      File.join(File.dirname(__FILE__), '../fixtures')
  end

end