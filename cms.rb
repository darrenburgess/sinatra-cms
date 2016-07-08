require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'pry'

=begin
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
