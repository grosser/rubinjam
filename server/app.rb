require 'sinatra'
require 'open-uri'
require 'tmpdir'
require 'rubinjam'

get "/pack/:gem/?:version?" do
  content_type 'text/plain'
  Rubinjam.pack_gem(params[:gem], params[:version]).last
end
