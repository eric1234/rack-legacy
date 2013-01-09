require 'test/unit'

require 'rack/legacy/php_server'
require 'rack/legacy/htaccess'

class PhpServerTest < Test::Unit::TestCase

  def test_valid?
    # Same restrictions as parent class
    assert app.valid?('success.php') # Valid file
    assert !app.valid?('../unit/php_test.rb') # Valid file but outside public
    assert !app.valid?('missing.php') # File not found
    assert !app.valid?('../fixtures/invalid.php') # Directory

    # Some new tests that are specific to php
    assert !app.valid?('success.cgi') # Valid file but not a php file
  end

  def test_parse_htaccess
    file = File.join(File.dirname(__FILE__), '../fixtures/dir1/dir2/.htaccess')
    assert_equal({
      'include_path'      => 'backend:ext:.',
      'auto_prepend_file' => 'backend/lib/setup.php',
      'auto_append_file'  => 'backend/lib/teardown.php',
      'output_buffering'  => 'off',
    }, Rack::Legacy::HtAccess.new(file).to_hash)
  end

  def test_htaccess_search
    file = File.join(File.dirname(__FILE__), '../fixtures/dir1/dir2/test.php')
    root = File.join(File.dirname(__FILE__), '../fixtures')
    assert_equal [
      File.join(File.dirname(__FILE__), '../fixtures/.htaccess'),
      File.join(File.dirname(__FILE__), '../fixtures/dir1/dir2/.htaccess'),
    ], Rack::Legacy::HtAccess.find_all(file, root).collect(&:file)
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
    }, Rack::Legacy::HtAccess.merge_all(file, root))

    assert_equal({},
      Rack::Legacy::HtAccess.merge_all(__FILE__, File.dirname(__FILE__)))
  end

  private

  def app
    Rack::Legacy::PhpServer.new \
      proc {[200, {'Content-Type' => 'text/html'}, 'Endpoint']},
      File.join(File.dirname(__FILE__), '../fixtures')
  end

end
