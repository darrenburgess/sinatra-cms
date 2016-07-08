require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'pry'

=begin
viewing markdown files
- markdown files can be converted using the redcarpet gem
- add redcarpet to the gemfile
- require redcarpet in the application
- run bundle install to install the gem
- rename the content files to *.md
- modify the content data to use markdown
- create a method to convert markdown
  - create a new markdown object
  - return the rendered markdown content
  - use the markdown.render method to render the content as html
- create new content erb
  - create a new view erb file to render accept the rendered html
- invoke the new erb layout in the /data/:file_name route
- update tests to test for converted mark down
=end

configure do
  enable :sessions
  set :session_secret, "secret"
end

before do
  @files = Dir["./data/*"].map { |f| File.basename f }
end

def render_as_html(mark_down)
  markdown = Redcarpet::Markdown.new Redcarpet::Render::HTML
  markdown.render mark_down
end

get "/" do
  erb :index, layout: :layout
end

get "/data/:file_name" do
  file_name = params[:file_name]
  full_path = "data/#{file_name}"

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
    session[:error] = "#{file_name} does not exist!"
    redirect "/"
  end
end
