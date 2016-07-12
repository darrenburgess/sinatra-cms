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

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "New Document"
    assert_includes last_response.body, "Delete"
  end

  def test_text_data
    create_document "changes.txt", "changes text"

    get "/changes.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "changes text"
  end

  def test_markdown_data
    create_document "about.md", "# about heading text"

    get "about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>about heading text</h1>"
  end

  def test_nonexistant_file
    get "/garbage_file.testing"

    assert_equal 302, last_response.status

    get last_response["location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "garbage_file.testing does not exist"
  end

  def test_edit_view
    create_document "about.md", "test content"

    get "/about.md/edit"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Edit content of: about.md"
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, "test content"
  end

  def test_file_save
    create_document "about.md", "test content"

    post "/about.md", content: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "about.md was successfully updated"

    get "/about.md"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content" 
  end

  def test_new_document_view
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Create a new document"
    assert_includes last_response.body, "<input"
  end

  def test_create_new_document
    post "/new", file_name: "test.txt"

    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test.txt was successfully created!"

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_no_name_for_new_document
    post "/new", file_name: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "File name cannot be empty"
  end

  def test_document_destroy
    create_document "test.txt", "content for test"

    post "/test.txt/destroy"
    assert_equal 302, last_response.status

    get last_response["Location"] 
    assert_includes last_response.body, "test.txt was successfully deleted"

    get "/test.txt"
    assert_equal 302, last_response.status

    get "/"
    assert_includes last_response.body, "test.txt does not exist"

    get "/"
    refute_includes last_response.body, "test.txt does not exist"
    refute_includes last_response.body, "test.txt"
  end

  def test_signin_form
    get "/users/signin"
    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Please log in:"
  end
end
