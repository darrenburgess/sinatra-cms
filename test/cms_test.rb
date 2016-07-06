ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
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
    assert_equal "", last_response.body
  end

  def test_data
    get "/data/about.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_equal "about text\n", last_response.body
  end
end
