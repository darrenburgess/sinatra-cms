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
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.md"
  end

  def test_text_data
    get "/data/changes.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "changes text"
  end

  def test_markdown_data
    get "/data/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>about heading text</h1>"
  end

  def test_nonexistant_file
    get "/data/garbage_file.testing"
    assert_equal 302, last_response.status

    get last_response["location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "garbage_file.testing does not exist"
  end

  def test_edit_view
    get "/data/about.md/edit"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Edit content of: about.md"
    assert_includes last_response.body, "<textarea"
  end

  def test_file_save
    post "/data/about.md/save", content: "new content"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "about.md has been updated"

    get "/data/about.md"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content" 
  end
end
