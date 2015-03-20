#!/usr/bin/env ruby
require 'fog/softlayer'
require 'optparse'
require 'optparse/time'
require 'ostruct'
# require 'pp'
require 'yaml'

config = YAML.load_file('config.yml')
Version = [0, 1]

class Optparser

	#
	# Return a structure describing the options.
	#
	def self.parse(args)
		# The options specified on the command line will be collected in *options*.
		# We set default values here.
		options = OpenStruct.new
		options.verbose = false
		options.provider = "digitalocean"
		options.action = "status"

		opt_parser = OptionParser.new do |opts|
			opts.banner = "Usage: ucli.rb [options]"

			opts.separator ""
			opts.separator "Specific options:"

			# Cast 'delay' argument to a Float.
			opts.on("--delay N", Float, "Delay N seconds before executing") do |n|
				options.delay = n
			end

			# Cast 'time' argument to a Time object.
			opts.on("-t", "--time [TIME]", Time, "Begin execution at given time") do |time|
				options.time = time
			end

			# Boolean switch.
			opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
				options.verbose = v
			end

			# Cloud provider.
			opts.on("-p", "--provider [PROVIDER]", String, "Select cloud provider") do |provider|
				options.provider = provider
			end

			# Action for VPS.
			opts.on("-a", "--action [ACTION]", String, "Select action for VPS: create, destroy, start, stop, reboot, status") do |action|
				options.action = action
			end

			# VPS name.
			opts.on("-n", "--name [NAME]", String, "Name of VPS") do |vps_name|
				options.vps_name = vps_name
			end

			opts.separator ""
			opts.separator "Common options:"

			# No argument, shows at tail.	This will print an options summary.
			# Try it and see!
			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				exit
			end

			# Another typical switch to print the version.
			opts.on_tail("--version", "Show version") do
				print "uCLI v", ::Version.join('.'), "\n"
				exit
			end

		end

		opt_parser.parse!(args)
		options
	end	# parse()

end	# class Optparser

if ARGV.count == 0
	options = Optparser.parse %w[--help]
# elsif raise exception
else
	options = Optparser.parse(ARGV)
end



case options["provider"]
when "softlayer"
	@vps_name = options["vps_name"]
	@sl = Fog::Compute.new(provider: config['provider'], softlayer_username: config['softlayer_username'], softlayer_api_key: config['softlayer_api_key'])
	n = 0
	until n == @sl.servers.size || @srv_id != nil
		srv_hash = JSON.parse @sl.servers.to_json
		srv_hash[n].select { |k,v| @srv_id = srv_hash[n]["id"] if v == @vps_name }
		n += 1
	end
	@srv = @sl.servers.get(@srv_id)
	def vps_status
		puts "VPS #{@vps_name} (id #{@srv_id}) status is #{@srv.state}."
	end
	# actions
	case options["action"]
	when "status"
		vps_status
	when "start"
		if @srv.state == "Halted" then @srv.start else puts "Can't start VPS." end
		vps_status
	when "stop"
		if @srv.state == "Running" then @srv.stop else puts "Can't stop VPS." end
		vps_status
	when "create"
		puts "create"
		vps_status
	when "destroy"
		if @srv.state == "Halted" then @srv.destroy else puts "Can't destroy VPS." end
		vps_status
	else
		options = Optparser.parse %w[--help]
	end
when "digitalocean"
	puts 'Try harder!'
else
	options = Optparser.parse %w[--help]
end

