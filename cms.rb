require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'

=begin
viewing text files
- convert list of files to links using hrefs
- point each link to the location of the file
- create a route to display the text file
- the browser will display the file as plain text
- set content-type so browser will display as plain text
=end

get "/" do
  @files = Dir["./data/*"].map { |f| File.basename f }
  erb :index, layout: :layout 
end

get "/data/:file_name" do
  file_name = params[:file_name]
  file = File.open "data/#{file_name}"

  headers["Content-Type"] = "text/plain"
  @content = file.read
end
