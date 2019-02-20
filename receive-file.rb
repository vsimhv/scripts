require 'webrick'
require 'securerandom'

#
# send file with curl:
# curl -F "file=@/path/to/test" http://127.0.0.1:8000
#

class Echo < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)
    response.status = 200
  end
  def do_POST(request, response)
    filename = "data-#{SecureRandom.hex(6)}.out"
    file = File.new(filename, "w+")
    data = request.query["file"]
    file.write(data)
    file.close
    puts "File saved as: #{filename}"
    response.status = 200
  end
end

server = WEBrick::HTTPServer.new(:Port => 8000)
server.mount "/", Echo
trap "INT" do server.shutdown end
server.start
