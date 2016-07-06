require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'

=begin
add tests
- create a cms_test.rb file in new test directory
- add testing setup code and required libraries
- create a CmsTest class that subclasses from Minitest::Test 
- write tests for testing the index route
- write tests for testing the data/file route
=end

get "/" do
  @files = Dir["./data/*"].map { |f| File.basename f }
  erb :index, layout: :layout 
end

get "/data/:file_name" do
  file_name = params[:file_name]
  file = File.open "data/#{file_name}"

  headers["Content-Type"] = "text/plain"
  @content = file.read
end
