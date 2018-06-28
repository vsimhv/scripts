#!/usr/bin/env ruby
require 'nmap/xml'
require 'optparse'

class NmapParser

  class Matcher
    def self.ip(ip, host)
      ip.nil? or host.ip.include?(ip)
    end

    def self.service(service, port)
      service.nil? or port.service.name.downcase.include?(service.downcase)
    end

    def self.port(port_number, port)
      port_number.nil? or port.number == port_number
    end

    def self.product(product, port)
      product.nil? or
      (product.empty? and not port.service.product.nil?) or
      (not product.empty? and not port.service.product.nil? and
        port.service.product.downcase.include?(product.downcase))
    end
  end

  @nmapXml = nil
  @options = nil

  def initialize(options)
    @options = options
    @nmapXml = Nmap::XML.new(options[:input]) 

    print_info if (@options[:verbose])
    search_services
  end

  def print_info
    print "Scan".ljust(10)
    puts @nmapXml.run_stats
    print "Type:".ljust(10)
    puts @nmapXml.scan_info
    print "Command:".ljust(10)
    puts @nmapXml.scanner.arguments
    print "Version:".ljust(10)
    puts @nmapXml.scanner.version
  end

  def search_services
    print_search_summary if (@options[:verbose])
    @nmapXml.each_up_host do |host|
      host.each_open_port do |port|
        if (Matcher.ip(@options[:ip], host))
          if (not port.service.nil? and 
              Matcher.service(@options[:service], port) and
              Matcher.port(@options[:port], port) and
              Matcher.product(@options[:product], port)
             )
            print_service(host, port)
          end
        end
      end
    end
  end

  def print_search_summary
    print "\nHosts with "
    print "port: #{@options[:port]} opened" if @options[:port]
    print " and " if @options[:port] and @options[:service]
    puts "service name: '#{@options[:service]}'" if @options[:service]
  end

  def print_service(host, port)
    print "#{host.ip}:#{port.number}"
    print "\t#{port.service.name}"
    print "\t#{port.service.product}"
    puts "\t#{port.service.version}"
  end
end

class NmapParserOptions

  def self.parse(args)
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename($0)} -f NMAP_XML"
      opts.on("-v", "--verbose") do
        options[:verbose] = true
      end
      opts.on("-P", "--product [NAME]", "Show only ports with discovered product name") do |val|
        options[:product] = val.nil? ? "" : val
      end
      opts.on("-f", "--file NMAP_XML", String,
              "Nmap XML output file") do |val|
        options[:input] = val
      end
      opts.on("-s", "--service NAME", String,
              "Search for services with specified name") do |val|
        options[:service] = val
      end
      opts.on("-p", "--port NUMBER", Integer,
              "Search for services with specified port") do |val|
        options[:port] = val
      end
      opts.on("-i", "--ip IP", String,
              "Search for hosts with specified ip address") do |val|
        options[:ip] = val
      end
    end.parse!

    if (options[:input].nil?)
      raise "Nmap XML file not specified"
    end

    unless (File.exist?(options[:input]))
      raise "Nmap XML file '#{options[:input]}' does not exist!"
    end
    options
  end
end

begin
  options = NmapParserOptions.parse(ARGV)
  NmapParser.new(options)
rescue Exception => e
  puts e
end
