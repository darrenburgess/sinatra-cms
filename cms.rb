require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'pry'

=begin
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

def load_users
  YAML::load(File.open "data/users.yml")
end

def signed_in?
  session[:username]
end

def not_signed_in?
  !session[:username]
end

def redirect_when_signed_out
  if not_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

get "/" do
  erb :index, layout: :layout
end

get "/users/signin" do
  erb :signin, layout: :layout
end

post "/users/signin" do
  username = params[:username]
  password = params[:password]
  users = load_users
  entered_password = users[username].first unless users[username] == nil

  if entered_password == password
    session[:username] = username
    session[:message] = "Welcome, #{username}"
    redirect "/"
  else
    session[:message] = "Incorrect username or password"
    status 422
    @username = username
    erb :signin, layout: :layout
  end
end

post "/users/signout" do
  username = session.delete(:username)
  session[:message] = "#{username} has been successfully signed out"
  redirect "/users/signin"
end

get "/new" do
  redirect_when_signed_out
  erb :new, layout: :layout
end

post "/new" do
  redirect_when_signed_out

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
  redirect_when_signed_out

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
  redirect_when_signed_out

  file_name = params[:file_name]
  full_path = File.join(data_path, file_name)
  content = params[:content]

  File.write full_path, content
  session[:message] =  "#{file_name} was successfully updated!"
  redirect "/"
end

get "/:file_name" do
  redirect_when_signed_out

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
  redirect_when_signed_out

  file_name = params[:file_name]
  full_path = File.join(data_path, file_name)

  File.delete full_path

  session[:message] = "#{file_name} was successfully deleted"
  redirect "/"
end

