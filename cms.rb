require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'pry'

=begin
signing in and out
- create a session property related to signing in and out. username: user and logged_in: true
- redirect index route to users/signin when session[:logged_in] == false
- create a new signin form template
  - add username and password form fields
  - add sign in button
  - form should have an action to submit credentials, checking if username = admin and password = secret
- create a userlogin route to check credentials or return error
  - check credentials
  - update login session property
  - redirect to index with welcome flash message
  - return error on incorrect credetials
- modify index template
  - add text to indicate signed in user
  - add sign out button
- create route to signout the current user
  - set the session signout property
  - redirect to signin view with signout successful flash message
- tests
  - content of signin form
  - redirect to signin form when no user is logged in (session user is nil)
=end

configure do
  enable :sessions
  set :session_secret, "secret"
end

before do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map { |path| File.basename path }
end

def render_as_html(mark_down)
  markdown = Redcarpet::Markdown.new Redcarpet::Render::HTML
  markdown.render mark_down
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

get "/" do
  if session[:username]
    erb :index, layout: :layout
  else
    redirect "/users/signin"
  end
end

get "/users/signin" do
  erb :signin, layout: :layout
end

post "/users/signin" do
  username = params[:username]
  password = params[:password]

  if username == "admin" && password == "secret"
    session[:username] = username
    session[:message] = "Welcome, #{username}"
    redirect "/"
  else
    session[:message] = "Incorrect username or password"
    status 422
    @username = username
    erb :signin
  end
end

post "/users/signout" do
  username = session.delete(:username)
  session[:message] = "#{username} has been successfully signed out"
  redirect "/"
end

get "/new" do
  erb :new, layout: :layout
end

post "/new" do
  file_name = params[:file_name].to_s.strip

  if file_name.size == 0
    session[:message] = "File name cannot be empty"
    status 422
    erb :new, layout: :layout
  else
    full_path = File.join(data_path, file_name)

    File.write full_path, ""
    session[:message] = "#{file_name} was successfully created!"

    redirect "/"
  end
end

get "/:file_name/edit" do
  @file_name = params[:file_name]
  full_path = File.join(data_path, @file_name)

  if File.exist? full_path
    file = File.open full_path
    @content = file.read
    erb :edit, layout: :layout
  else
    session[:error] = "#{@file_name} does not exist!"
    redirect "/"
  end
end

post "/:file_name" do
  file_name = params[:file_name]
  full_path = File.join(data_path, file_name)
  content = params[:content]

  File.write full_path, content
  session[:message] =  "#{file_name} was successfully updated!"
  redirect "/"
end

get "/:file_name" do
  file_name = params[:file_name]
  full_path = File.join(data_path, file_name)

  if File.exist? full_path
    file = File.open full_path

    case File.extname full_path
    when ".txt"
      headers["Content-Type"] = "text/plain"
      file.read
    when ".md"
      @html = render_as_html(file.read)
      erb :content, layout: :layout
    end
  else
    session[:message] = "#{file_name} does not exist!"
    redirect "/"
  end
end

post "/:file_name/destroy" do
  file_name = params[:file_name]
  full_path = File.join(data_path, file_name)

  File.delete full_path

  session[:message] = "#{file_name} was successfully deleted"
  redirect "/"
end

