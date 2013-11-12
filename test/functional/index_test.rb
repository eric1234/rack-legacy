require 'minitest/autorun'
require 'mechanize'

class IndexTest < MiniTest::Unit::TestCase

  def test_no_path
    response = Mechanize.new.get 'http://localhost:4000'
    assert_equal 'PHP index', response.body

    response = Mechanize.new.get 'http://localhost:4000/'
    assert_equal 'PHP index', response.body
  end

  def test_dir
    response = Mechanize.new.get 'http://localhost:4000/dir1'
    assert_equal 'PHP dir1 index', response.body

    response = Mechanize.new.get 'http://localhost:4000/dir1/'
    assert_equal 'PHP dir1 index', response.body

    response = Mechanize.new.get 'http://localhost:4000/dir2'
    assert_equal 'Endpoint', response.body

    response = Mechanize.new.get 'http://localhost:4000/dir2/'
    assert_equal 'Endpoint', response.body
  end

end
