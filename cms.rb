require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'

get "/" do
  "hello, world"
end
