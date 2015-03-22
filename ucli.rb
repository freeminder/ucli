#!/usr/bin/env ruby

require 'fog/softlayer'
require 'thor'
require 'yaml'


class ThorClass < Thor
	class OptionsHelper
		def self.method_options
			ThorClass.method_option :provider, :type => :string, :default => "softlayer", :aliases => "-p", :desc => "Select cloud provider"
			ThorClass.method_option :name, :type => :string, :default => false, :aliases => "-n", :desc => "Name of VPS"
			ThorClass.method_option :region, :type => :string, :default => false, :aliases => "-r", :desc => "Region of datacenter"
		end
		def self.method_options_create
			ThorClass.method_option :image, :type => :string, :default => false, :aliases => "-i", :desc => "Image of Linux distro"
			ThorClass.method_option :cpu, :type => :string, :default => false, :aliases => "-c", :desc => "Numbers of CPU"
			ThorClass.method_option :ram, :type => :string, :default => false, :aliases => "-m", :desc => "Memory size"
		end
	end

	no_commands do
		def sl_actions_init
			@config = YAML.load_file('config.yml')
			@sl = Fog::Compute.new(provider: @config['provider'], softlayer_username: @config['softlayer_username'], softlayer_api_key: @config['softlayer_api_key'])
			@vps_name = options['name']
			n = 0
			until n == @sl.servers.size || @srv_id != nil
				srv_hash = JSON.parse @sl.servers.to_json
				srv_hash[n].select { |k,v| @srv_id = srv_hash[n]["id"] if v == @vps_name }
				n += 1
			end
			if ARGV[0] == "create"
				@opts = {
					:cpu => options['cpu'],
					:ram => options['ram'],
					:disk => [{'device' => 0, 'diskImage' => {'capacity' => 100 } }],
					:ephemeral_storage => true,
					:domain => "webenabled.net",
					:name => "hostname",
					:os_code => options['image'],
					:name => options['name'],
					:datacenter => options['region']
				}
				return
			else
				abort "No VPS found with this name. Exiting." if @srv_id == nil
			end
			@srv = @sl.servers.get(@srv_id)

		end
		def vps_status
			puts "VPS #{@vps_name} (id #{@srv_id}) status is #{@srv.state}."
		end
	end


	desc "status", "status of server"
	OptionsHelper.method_options
	def status
		sl_actions_init
		vps_status
	end

	desc "create", "create server"
	OptionsHelper.method_options
	OptionsHelper.method_options_create
	def create
		sl_actions_init
		@sl.servers.create(@opts)
		puts "VPS has been created and will be ready in a few minutes."
	end

	desc "start", "start server"
	OptionsHelper.method_options
	def start
		sl_actions_init
		if @srv.state == "Halted" then @srv.start else puts "Can't start VPS." end
		puts "VPS has been started."
		vps_status
	end

	desc "stop" ,"stop server"
	OptionsHelper.method_options
	def stop
		sl_actions_init
		if @srv.state == "Running" then @srv.stop else puts "Can't stop VPS." end
		puts "VPS has been stopped."
		vps_status
	end

	desc "reboot" ,"reboot server"
	OptionsHelper.method_options
	def reboot
		sl_actions_init
		if @srv.state == "Running" then @srv.reboot else puts "Can't reboot VPS." end
		puts "VPS has been restarted."
		vps_status
	end

	desc "destroy" ,"destroy server"
	OptionsHelper.method_options
	def destroy
		sl_actions_init
		if @srv.state == "Halted" then @srv.destroy else puts "Can't destroy VPS." end
		puts "VPS has been destroyed."
		vps_status
	end

end

ThorClass.start
