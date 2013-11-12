require 'minitest/autorun'
require 'rack/legacy'
require 'rack/legacy/index'

class IndexTest < MiniTest::Unit::TestCase

  def test_no_path
    response = app.call  'PATH_INFO' => ''
    assert_equal 200, response.first
    assert_equal ['/index.php'], response.last

    response = app.call  'PATH_INFO' => '/'
    assert_equal 200, response.first
    assert_equal ['/index.php'], response.last
  end

  def test_dir
    response = app.call  'PATH_INFO' => '/dir1'
    assert_equal 200, response.first
    assert_equal ['/dir1/index.php'], response.last

    response = app.call  'PATH_INFO' => '/dir1/'
    assert_equal 200, response.first
    assert_equal ['/dir1/index.php'], response.last

    response = app.call  'PATH_INFO' => '/dir2'
    assert_equal 200, response.first
    assert_equal ['/dir2'], response.last

    response = app.call  'PATH_INFO' => '/dir2/'
    assert_equal 200, response.first
    assert_equal ['/dir2/'], response.last
  end

  def test_fallback
    app = Rack::Legacy::Index.new \
      proc {|env| [200, {'Content-Type' => 'text/html'}, [env['PATH_INFO']]]},
      File.join(File.dirname(__FILE__), '../fixtures'), ['index.pl', 'index.html']

    response = app.call  'PATH_INFO' => '', 'REQUEST_METHOD' => 'GET'
    assert_equal 200, response.first
    assert_equal ['/index.html'], response.last
  end

  private

  def app
    @app ||= Rack::Legacy::Index.new \
      proc {|env| [200, {'Content-Type' => 'text/html'}, [env['PATH_INFO']]]},
      File.join(File.dirname(__FILE__), '../fixtures')
  end
end
