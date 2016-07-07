require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
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

get "/" do
  erb :index, layout: :layout
end

get "/data/:file_name" do
  file_name = params[:file_name]
  full_path = "data/#{file_name}"

  if File.exist? full_path
    file = File.open full_path
    headers["Content-Type"] = "text/plain"
    file.read
  else
    session[:error] = "#{file_name} does not exist!"
    redirect "/"
  end
end
