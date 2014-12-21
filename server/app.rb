require 'sinatra'
require 'sinatra/streaming'
require 'open-uri'
require 'tmpdir'
require 'rubinjam'

# increase the timeout by fake streaming the response
# test with `time curl https://rubinjam.herokuapp.com/pack/s3_meta_sync -vvv > s3-meta-sync`
def stream_result(out, work)
  buffer = Rubinjam::HEADER.dup
  loop do
    break if buffer.empty?
    20.times do # check often -> don't hang for long
      if !work.alive?
        out.print buffer # we are done, write the remaining buffer
        out.print work.value.sub(Rubinjam::HEADER, '')
        return
      end
      sleep 1
    end
    out.print buffer.slice!(0, 1)
    out.flush
  end

  # we already sent the '200 OK' ... tell the user something useful ...
  out.print "\nraise 'code generation took too long'"
end

get "/pack/:gem/?:version?" do
  content_type 'text/plain'
  work = Thread.new { Rubinjam.pack_gem(params[:gem], params[:version]).last }
  stream do |out|
    stream_result(out, work)
  end
end
