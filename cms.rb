require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'pry'

=begin
creating new documents
- add a link to index that navigates to new document page
- add a route for the new document creation form
- create a new template for the new document form
- add a route to create a new document
  - flash message should read "doc_name was created"
  - if user does not supply a name flash message = "a name is required"
  - redirect user to index with flash message on successful creation
  - redirect to edit for on empty name
- add tests
  - new document form
  - creation of new document
  - flash message for no document name  
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
  erb :index, layout: :layout
end

get "/new" do
  erb :new, layout: :layout
end

post "/new" do
  file_name = params[:file_name].to_s.strip

  if file_name.size > 0
    session[:message] = "File name cannot be empty"
    redirect "/new"
  else
    full_path = File.join(data_path, file_name)

    File.write file_path, ""
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

