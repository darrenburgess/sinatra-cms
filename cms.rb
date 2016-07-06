require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'

# plan:
# - create a public directory
# - create three text documents: about, changes, history
# - modify the home route to capture the file names in the public directory
# - create home.erb file with unordered list of the files
# - create a layout.erb file with basic html structure

get "/" do
  @files = Dir["./data/*"].map { |f| File.basename f }
  erb :home, layout: :layout 
end
