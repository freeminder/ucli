#!/usr/bin/env ruby

require 'fog'
require 'thor'
require 'yaml'


# class for create action's subcommands
class Create < Thor
	option :name, :type => :string, :default => false, :aliases => "-n", :desc => "Name of VPS"
	option :region, :type => :string, :default => false, :aliases => "-r", :desc => "Region of datacenter"
	option :image, :type => :string, :default => false, :aliases => "-i", :desc => "Image of Linux distro"
	option :cpu, :type => :string, :default => false, :aliases => "-c", :desc => "Numbers of CPU"
	option :ram, :type => :string, :default => false, :aliases => "-m", :desc => "Memory size in MB"
	option :config, :type => :string, :default => false, :desc => "Configuration options for new VPS"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Provider's credentials for new VPS"
	option :provider, :type => :string, :default => "softlayer", :aliases => "-p", :desc => "Provider for new VPS"


	desc "vps <profile> <name> <region> <image> <cpu> <ram> OR vps <profile> <config>", "Creates VPS at specified cloud provider"
	def vps
		if ARGV.include? '--config'
			if File.exist?("#{options['config']}")
				@opts = YAML.load_file("#{options['config']}")
			else
				abort "No config found. You have to create configuration file first. Exiting."
			end
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
			p @opts
		end

		if ARGV.include? '--profile'
			if File.exist?("#{options['profile']}")
				@profile = YAML.load_file("#{options['profile']}")
			elsif File.exist?("#{ENV['HOME']}/.ucli.yml")
				@profile = YAML.load_file("#{ENV['HOME']}/.ucli.yml")
			else
				abort "No profiles found. You have to create profiles file with credentials first. Exiting."
			end
		else
			abort "No profiles found. You have to create profiles file with credentials first. Exiting."
		end
		@cloud = eval(@profile[options['provider']])

		@cloud.servers.create(@opts)
		srv_hash = JSON.parse @cloud.servers.last.to_json
		print "VPS is currently in the provisioning process"
		until @cloud.servers.get(srv_hash["id"]).ready? == true
			print "."
			sleep 3
		end
		print "\n"
		puts "VPS has been created and ready to use"
	end

	desc "directory <name>", "Creates directory at storage provider"
	def directory(name)
		p "Storage work to be done here"
	end
end

# main class
class ThorClass < Thor
	# class for generic actions (commands)
	class OptionsHelper
		def self.method_options
			ThorClass.method_option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Provider's credentials for new VPS"
			ThorClass.method_option :provider, :type => :string, :default => "softlayer", :aliases => "-p", :desc => "Provider for new VPS"
			ThorClass.method_option :name, :type => :string, :default => false, :aliases => "-n", :desc => "Name of VPS"
			ThorClass.method_option :region, :type => :string, :default => false, :aliases => "-r", :desc => "Region of datacenter"
		end
	end

	# methods for generic actions
	no_commands do
		def actions_init
			if ARGV.include? '--profile'
				if File.exist?("#{options['profile']}")
					@profile = YAML.load_file("#{options['profile']}")
				elsif File.exist?("#{ENV['HOME']}/.ucli.yml")
					@profile = YAML.load_file("#{ENV['HOME']}/.ucli.yml")
				else
					abort "No profiles found. You have to create profiles file with credentials first. Exiting."
				end
			else
				abort "No profiles found. You have to create profiles file with credentials first. Exiting."
			end
			@cloud = eval(@profile[options['provider']])

			@vps_name = options['name']
			n = 0
			until n == @cloud.servers.size || @srv_id != nil
				srv_hash = JSON.parse @cloud.servers.to_json
				srv_hash[n].select { |k,v| @srv_id = srv_hash[n]["id"] if v == @vps_name }
				n += 1
			end
			abort "No VPS found with this name. Exiting." if @srv_id == nil
			@srv = @cloud.servers.get(@srv_id)
		end
		def vps_status
			puts "VPS #{@vps_name} (id #{@srv_id}) status is #{@srv.state}"
		end
	end

	# generic actions
	desc "status", "status of server"
	OptionsHelper.method_options
	def status
		actions_init
		vps_status
	end

	desc "start", "start server"
	OptionsHelper.method_options
	def start
		actions_init
		if @srv.state == "Halted" || @srv.state == "off"
			@srv.start
			print "VPS is currently in the booting process"
			until @srv.state == "Running" || @srv.state == "active"
				print "."
				sleep 3
				actions_init
			end
			print "\n"
			puts "VPS has been started"
		else
			puts "Can't start VPS. Please check that VPS is in halted or off state."
		end
		vps_status
	end

	desc "stop" ,"stop server"
	OptionsHelper.method_options
	def stop
		actions_init
		if @srv.state == "Running" || @srv.state == "active"
			@srv.stop
			print "VPS is currently in the shutting down process"
			until @srv.state == "Halted" || @srv.state == "off"
				print "."
				sleep 3
				actions_init
			end
			print "\n"
			puts "VPS has been stopped"
		else
			puts "Can't stop VPS. Please check that VPS is in running or active state."
		end
		vps_status
	end

	desc "reboot" ,"reboot server"
	OptionsHelper.method_options
	def reboot
		actions_init
		if @srv.state == "Running" || @srv.state == "active"
			@srv.reboot
			print "VPS is currently in the restarting process"
			until @srv.state == "Running" || @srv.state == "active"
				print "."
				sleep 3
				actions_init
			end
			print "\n"
			puts "VPS has been restarted"
		else
			puts "Can't reboot VPS. Please check that VPS is in running or active state."
		end
		vps_status
	end

	desc "destroy" ,"destroy server"
	OptionsHelper.method_options
	def destroy
		actions_init
		if @srv.state == "Halted" || @srv.state == "off"
			@srv.destroy
			print "VPS is currently in the destroying process"
			until @vps_status == "No VPS found with this name. Exiting."
				print "."
				sleep 3
				@vps_status = `#{$0} status -n #{@vps_name} --profile #{options['profile']} --provider #{options['provider']} 2>&1`.chomp
			end
			print "\n"
			puts "VPS has been destroyed"
		else
			puts "Can't destroy VPS. Please check that VPS is in halted or off state."
			vps_status
		end
	end

	# create action calls Create class with subcommands
	desc "create SUBCOMMAND ...ARGS", "create vps or directory"
	subcommand "create", Create

end


ThorClass.start
