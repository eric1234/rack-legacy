require 'test/unit'

require 'rubygems'
require 'nokogiri'

require 'rack/legacy/error_page'

class ErrorPageTest < Test::Unit::TestCase

  def test_all
    page = Rack::Legacy::ErrorPage.new(
      {'PATH_INFO' => 'error_page.cgi', 'foo' => 'bar'},
      {'baz' => 'boo'}, 'Standard Out', 'Standard Error').to_s
    page = Nokogiri::HTML page
    assert_match /error_page\.cgi/, page.search('p').first.content

    assert_equal 'Standard Out', page.search('pre code')[0].content
    assert_equal 'Standard Error', page.search('pre code')[1].content

    assert_equal 2, page.search('table').size

    assert_equal 1, page.search('table')[0].search('tr').size
    assert_equal 'baz', page.search('table th')[0].content
    assert_equal 'boo', page.search('table td')[0].content

    assert_equal 2, page.search('table')[1].search('tr').size
    assert_equal 'PATH_INFO', page.search('table th')[1].content
    assert_equal 'error_page.cgi', page.search('table td')[1].content
    assert_equal 'foo', page.search('table th')[2].content
    assert_equal 'bar', page.search('table td')[2].content
  end

  def test_standard_out_collapse
    page = Rack::Legacy::ErrorPage.new(
      {'PATH_INFO' => 'error_page.cgi', 'foo' => 'bar'},
      {'baz' => 'boo'}, '', 'Standard Error').to_s
    page = Nokogiri::HTML page
    assert_equal 'Standard Error', page.search('pre code').first.content 
  end

  def test_standard_error_collapse
    page = Rack::Legacy::ErrorPage.new(
      {'PATH_INFO' => 'error_page.cgi', 'foo' => 'bar'},
      {'baz' => 'boo'}, 'Standard Out', '').to_s
    page = Nokogiri::HTML page
    assert_equal 1, page.search('pre code').size
    assert_equal 'Standard Out', page.search('pre code').first.content
  end

  def test_headers_collapse
    page = Rack::Legacy::ErrorPage.new(
      {'PATH_INFO' => 'error_page.cgi', 'foo' => 'bar'},
      {}, 'Standard Out', 'Standard Error').to_s
    page = Nokogiri::HTML page

    assert_equal 1, page.search('table').size
    assert_equal 'PATH_INFO', page.search('table th').first.content
  end

  def test_environment_collapse
    page = Rack::Legacy::ErrorPage.new({}, {'baz' => 'boo'},
      'Standard Out', 'Standard Error').to_s
    page = Nokogiri::HTML page

    assert_equal 1, page.search('table').size
    assert_equal 'baz', page.search('table th').first.content
  end

  def test_collapse_all
    page = Rack::Legacy::ErrorPage.new({}, {}, '', '').to_s
    page = Nokogiri::HTML page
    assert_equal 0, page.search('pre code').size
    assert_equal 0, page.search('table').size
  end
end