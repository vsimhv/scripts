#!/usr/bin/env ruby
require 'nmap/xml'
require 'optparse'

class NmapParser
  @nmapXml = nil
  @options = nil

  def initialize(options)
    @options = options
    @nmapXml = Nmap::XML.new(options[:input]) 

    if (@options[:verbose])
      info
    end

    case
    when @options[:search]
      search_services(@options[:search])
    when @options[:port]
      search_ports(@options[:port])
    else
      opened_ports
    end
  end

  def info
    print "Scan date: "
    puts @nmapXml.run_stats
    print "Scan type: "
    puts @nmapXml.scan_info
  end

  def opened_ports
    puts "\nOpened ports" if (@options[:verbose])

    @nmapXml.each_up_host do |host|
      host.each_open_port do |port|
        print "#{host.ip}:#{port.number}\t#{port.service}"
        print "\t#{port.service.product}" unless port.service.nil?
        puts
      end
    end
  end

  def search_services(search)
    puts "\nHosts with services matching search: #{search}" if (@options[:verbose])

    @nmapXml.each_up_host do |host|
      host.each_open_port do |port|
        if (not port.service.nil? and port.service.name.include?(search))
          print "#{host.ip}:#{port.number}\t#{port.service}"
          print "\t#{port.service.product}" unless port.service.nil?
          print "\t#{port.service.version}" unless port.service.nil?
          puts
        end
      end
    end
  end

  def search_ports(search)
    puts "\nHosts with opened port #{search}" if (@options[:verbose])

    @nmapXml.each_up_host do |host|
      host.each_open_port do |port|
        if (port.number == search)
          print "#{host.ip}:#{port.number}\t#{port.service}"
          print "\t#{port.service.product}" unless port.service.nil?
          puts
        end
      end
    end
  end

end

class NmapParserOptions

  def self.parse(args)
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename($0)} NMAP_XML"
      opts.on("-v", "--verbose") do
        options[:verbose] = true
      end
      opts.on("-f", "--file NMAP_XML", String, "Nmap XML output file") do |val|
        options[:input] = val
      end
      opts.on("-s", "--search SEARCH", String, "Search for services with specified name") do |val|
        options[:search] = val
      end
      opts.on("-p", "--port NUMBER", Integer, "Search for services with specified port opened") do |val|
        options[:port] = val
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
