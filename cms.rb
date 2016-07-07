require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'

=begin
handle requests for nonexistent documents
- add a not_found block that redirects to home
- add a check to the file display block to check if the file exists
- modify route to store a flash message on file error
- in layout.erb, create a conditional paragraph that
  displays if there is an error
- enable sessions in a configure block
  - use a configure block to enable sessions and set a session secret.
  - must restart server to get the session to work
- write a test:
  - execute the route with a nonexistant file
  - confirm the redirect
  - confirm the flash message text
=end

configure do
  enable :sessions
  set :session_secret, "secret"
end

before do
  @files = Dir["./data/*"].map { |f| File.basename f }
end

get "/" do
  erb :index, layout: :layout
end

get "/data/:file_name" do
  file_name = params[:file_name]
  full_path = "data/#{file_name}"

  if File.exist? full_path
    file = File.open full_path
    headers["Content-Type"] = "text/plain"
    @content = file.read
  else
    session[:error] = "#{file_name} does not exist!"
    redirect "/"
  end
end
