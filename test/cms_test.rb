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

  def session
    last_request.env["rack.session"]
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def sign_in_as_admin
    get "/", {}, admin_session
  end

  def test_index_when_signed_in
    create_document "about.md"
    create_document "changes.txt"

    get "/", {}, admin_session

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "New Document"
    assert_includes last_response.body, "Delete"
  end

  def test_text_data_when_signed_in
    create_document "changes.txt", "changes text"

    sign_in_as_admin
    get "/changes.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "changes text"
  end

  def test_markdown_data_when_signed_in
    create_document "about.md", "# about heading text"

    sign_in_as_admin
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>about heading text</h1>"
  end

  def test_nonexistant_file_when_signed_in
    get "/garbage_file.testing", {}, admin_session

    assert_equal 302, last_response.status

    get last_response["location"], {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "garbage_file.testing does not exist"
  end

  def test_edit_view_when_signed_in
    create_document "about.md", "test content"

    sign_in_as_admin
    get "/about.md/edit"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Edit content of: about.md"
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, "test content"
  end

  def test_file_save_when_signed_in
    create_document "about.md", "test content"

    sign_in_as_admin
    post "/about.md", content: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"], {}, admin_session
    assert_includes last_response.body, "about.md was successfully updated"

    get "/about.md"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content" 
  end

  def test_new_document_view_when_signed_in
    sign_in_as_admin
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Create a new document"
    assert_includes last_response.body, "<input"
  end

  def test_create_new_document_when_signed_in
    sign_in_as_admin
    post "/new", file_name: "test.txt"

    assert_equal 302, last_response.status

    get last_response["Location"], {}, admin_session
    assert_includes last_response.body, "test.txt was successfully created!"

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_no_name_for_new_document_when_signed_in
    sign_in_as_admin
    post "/new", file_name: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "File name cannot be empty"
  end

  def test_document_destroy_when_signed_in
    create_document "test.txt", "content for test"

    sign_in_as_admin
    post "/test.txt/destroy"
    assert_equal 302, last_response.status

    get last_response["Location"], {}, {"rack.session" => { username: "admin"} }
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

  def test_route_when_not_signed_in
    get "/"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "Please log in:"
    assert last_response, ""
  end

  def test_valid_signin
    post "/users/signin", username: "admin", password: "secret"
  
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "Welcome, admin"
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_invalid_signin
    post "/users/signin", username: "wrong_username", password: "wrong_password"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Incorrect username or password"
    assert_includes last_response.body, "wrong_username"
  end

  def test_signout
    get "/", {}, admin_session
    assert_includes last_response.body, "Signed in as admin"

    post "/users/signout"
    get last_response["Location"]

    assert_equal nil, session[:username]
    assert_includes last_response.body, "admin has been successfully signed out"
    assert_includes last_response.body, "Sign In"
  end
end
