require 'test/unit'

require 'rubygems'
require 'httparty'

require 'rack/legacy/php'

class PhpTest < Test::Unit::TestCase

  def test_success
    response = HTTParty.get('http://localhost:4000/success.php')
    assert_equal 'Success', response.body
    assert_equal 200, response.code
    assert_equal 'text/html', response.headers['content-type'].first
    assert_match /^PHP/, response.headers['x-powered-by'].first
  end

  # Should operate much like success
  def test_syntax_error
    response = HTTParty.get('http://localhost:4000/syntax_error.php')
    assert_match /Error/, response.body
    assert_equal 500, response.code
    assert_equal 'text/plain', response.headers['content-type'].first
  end

  def test_not_found
    response = HTTParty.get('http://localhost:4000/not_found.php')
    assert_match 'Endpoint', response.body
    assert_equal 200, response.code
    assert_equal 'text/html', response.headers['content-type'].first
  end

end