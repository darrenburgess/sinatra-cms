ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "pry"
require_relative "../cms.rb"

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_data
    get "/data/about.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_equal "about text\n", last_response.body
  end

  def test_nonexistant_file
    get "/data/garbage_file.testing"
    assert_equal 302, last_response.status

    get last_response["location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "garbage_file.testing does not exist"
  end
end
