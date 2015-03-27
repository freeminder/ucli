#!/usr/bin/env ruby

require 'fog/softlayer'
require 'thor'
require 'yaml'


class Create < Thor
	option :t, :banner => "<branch>"
	option :m, :banner => "<master>"
	options :f => :boolean, :tags => :boolean, :mirror => :string
	option :provider, :type => :string, :default => "softlayer", :aliases => "-p", :desc => "Select cloud provider"
	option :name, :type => :string, :default => false, :aliases => "-n", :desc => "Name of VPS"
	option :region, :type => :string, :default => false, :aliases => "-r", :desc => "Region of datacenter"
	option :image, :type => :string, :default => false, :aliases => "-i", :desc => "Image of Linux distro"
	option :cpu, :type => :string, :default => false, :aliases => "-c", :desc => "Numbers of CPU"
	option :ram, :type => :string, :default => false, :aliases => "-m", :desc => "Memory size in MB"
	option :config, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Configuration options for new VPS"

	desc "vps <provider> <name> <region>", "Creates VPS at specified cload provider"
	def vps
		if ARGV.include? '--config'
			@opts = YAML.load_file("#{options['config']}")
		else
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
		end
		@config = YAML.load_file('config.yml')
		@sl = Fog::Compute.new(provider: @config['provider'], softlayer_username: @config['softlayer_username'], softlayer_api_key: @config['softlayer_api_key'])
		@sl.servers.create(@opts)
		srv_hash = JSON.parse @sl.servers.last.to_json
		print "VPS is currently in the provisioning process"
		until @sl.servers.get(srv_hash["id"]).ready? == true
			print "."
			sleep 3
		end
		print "\n"
		puts "VPS has been created and ready to use."
	end

	desc "directory <name>", "Creates directory at storage provider"
	def directory(name)
		p "Storage work here"
	end
end


class ThorClass < Thor
	class OptionsHelper
		def self.method_options
			ThorClass.method_option :provider, :type => :string, :default => "softlayer", :aliases => "-p", :desc => "Select cloud provider"
			ThorClass.method_option :name, :type => :string, :default => false, :aliases => "-n", :desc => "Name of VPS"
			ThorClass.method_option :region, :type => :string, :default => false, :aliases => "-r", :desc => "Region of datacenter"
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
			abort "No VPS found with this name. Exiting." if @srv_id == nil
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

	desc "start", "start server"
	OptionsHelper.method_options
	def start
		sl_actions_init
		if @srv.state == "Halted"
			@srv.start
			puts "VPS has been started."
		else
			puts "Can't start VPS. Please check that VPS is in halted state."
		end
		vps_status
	end

	desc "stop" ,"stop server"
	OptionsHelper.method_options
	def stop
		sl_actions_init
		if @srv.state == "Running"
			@srv.stop
			puts "VPS has been stopped."
		else
			puts "Can't stop VPS. Please check that VPS is in running state."
		end
		vps_status
	end

	desc "reboot" ,"reboot server"
	OptionsHelper.method_options
	def reboot
		sl_actions_init
		if @srv.state == "Running"
			@srv.reboot
			puts "VPS has been restarted."
		else
			puts "Can't reboot VPS. Please check that VPS is in running state."
		end
		vps_status
	end

	desc "destroy" ,"destroy server"
	OptionsHelper.method_options
	def destroy
		sl_actions_init
		if @srv.state == "Halted"
			@srv.destroy
			puts "VPS has been destroyed."
		else
			puts "Can't destroy VPS. Please check that VPS is in halted state."
			vps_status
		end
	end

	desc "create SUBCOMMAND ...ARGS", "create vps or directory"
	subcommand "create", Create

end


ThorClass.start
