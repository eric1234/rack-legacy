# encoding: UTF-8
require 'test/unit'

require 'rubygems'
require 'mechanize'

require 'rack/legacy/php'

class PhpTest < Test::Unit::TestCase

  def test_success
    response = Mechanize.new.get 'http://localhost:4000/success.php'
    assert_equal 'Success', response.body
    assert_equal '200', response.code
    assert_equal 'text/html', response.header['content-type']
    assert_match /^PHP/, response.header['x-powered-by']
  end

  def test_error
    begin
      Mechanize.new.get 'http://localhost:4000/error.php'
    rescue Mechanize::ResponseCodeError
      assert_match /Internal Server Error/, $!.page.body
      assert_equal '500', $!.page.code
      assert_match /^text\/html/, $!.page.header['content-type']
    end
  end

  def test_syntax_error
    begin
      Mechanize.new.get 'http://localhost:4000/syntax_error.php'
    rescue Mechanize::ResponseCodeError
      assert_match /Internal Server Error/, $!.page.body
      assert_equal '500', $!.page.code
      assert_match /^text\/html/, $!.page.header['content-type']
    end
  end

  def test_non_ascii_error
    begin
      Mechanize.new.get 'http://localhost:4000/non_ascii_error.php'
    rescue Mechanize::ResponseCodeError
      assert_match /Internal Server Error/, $!.page.body
      assert_not_match /invalid byte sequence/, $!.page.body
      $!.page.body.force_encoding('UTF-8') # Revert ASCII-8BIT encoding forced by Mechanize
      assert_match /エラー/, $!.page.body
      assert_equal '500', $!.page.code
    end
  end

  def test_not_found
    response = Mechanize.new.get 'http://localhost:4000/not_found.php'
    assert_match 'Endpoint', response.body
    assert_equal '200', response.code
    assert_equal 'text/html', response.header['content-type']
  end

  def test_with_status
    assert_raises Mechanize::ResponseCodeError do
      Mechanize.new.get 'http://localhost:4000/404.php'
    end
  end

  def test_multiple_headers
    response = Mechanize.new.get 'http://localhost:4000/dup_headers.php'
    assert_equal '200', response.code
    assert_equal 'cookie1=, cookie2=', response.header['set-cookie']
    assert_equal 'text/html', response.header['content-type']
  end

  def test_querystring
    response = Mechanize.new.get 'http://localhost:4000/querystring.php', :q => 'query'
    assert_match 'query', response.body
    assert_equal '200', response.code
    assert_equal 'text/html', response.header['content-type']
  end

  def test_post
    response = Mechanize.new.post 'http://localhost:4000/post.php', :q => 'post'
    assert_match 'post', response.body
    assert_equal '200', response.code
    assert_equal 'text/html', response.header['content-type']
  end

  def test_flushing
    assert_nothing_raised do
      # 5 seconds should be enough to know it didn't lock up
      timeout 5 do
        response = Mechanize.new.get 'http://localhost:4000/flush.php'
        assert_equal '200', response.code
        assert_equal 'text/html', response.header['content-type']
      end
    end
  end

  def test_file_upload
    to_upload = File.join File.dirname(__FILE__), '../fixtures/uploaded_file.txt'
    response = Mechanize.new.post(
      'http://localhost:4000/upload.php',
      {:test => File.new(to_upload)}
    )
    assert_equal <<RESULT.chomp, response.body
Filename: uploaded_file.txt
Size: 22
Contents: A file to be uploaded.
RESULT
  end

end
