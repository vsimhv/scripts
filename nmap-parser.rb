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

    if (@options[:search])
      search_services(@options[:search])
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
    puts "\nOpened ports matching search: #{search}" if (@options[:verbose])

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
      opts.on("-s", "--search [SEARCH]", String, "Search string") do |val|
        options[:search] = val
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
