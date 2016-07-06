require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'

get "/" do
  @files = Dir["./data/*"].map { |f| File.basename f }
  erb :home, layout: :layout 
end
