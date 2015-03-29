#!/usr/bin/env ruby

require 'fog'
require 'thor'
require 'yaml'


# class for create action's subcommands
class Create < Thor
	option :name, :type => :string, :default => false, :aliases => "-n", :desc => "Name of VPS"
	option :region, :type => :string, :default => 3, :aliases => "-r", :desc => "Region of datacenter"
	option :image, :type => :string, :default => 9801950, :aliases => "-i", :desc => "Image of Linux distro"
	option :flavor, :type => :string, :default => 66, :aliases => "-f", :desc => "Flavor ID"
	option :size, :type => :string, :default => 33, :aliases => "-s", :desc => "Size ID"
	option :cpu, :type => :string, :default => 2, :aliases => "-c", :desc => "Numbers of CPU"
	option :ram, :type => :string, :default => 1024, :aliases => "-m", :desc => "Memory size in MB"
	option :provider, :type => :string, :default => "softlayer", :aliases => "-p", :desc => "Provider for new VPS"
	option :config, :type => :string, :default => "config_example_softlayer", :desc => "Path to configuration file with options for new VPS"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Path to provider's credentials for new VPS"
	option :public_key, :type => :string, :default => "#{ENV['HOME']}/.ssh/id_rsa.pub", :desc => "Public key's path"
	option :private_key, :type => :string, :default => "#{ENV['HOME']}/.ssh/id_rsa", :desc => "Private key's path"
	option :ssh_key_id, :type => :string, :default => false, :desc => "SSH key's ID"

	desc "vps <profile> <name> <region> <image> <cpu> <ram> OR vps <profile> <config>", "Creates VPS at specified cloud provider"
	def vps
		if ARGV.include? '--config'
			if File.exist?("#{options['config']}")
				@opts = YAML.load_file("#{options['config']}")
			else
				abort "No config found. You have to create configuration file first. Exiting."
			end
		else
			# read and set options from command line arguments to the selected provider
			@opts = {
				:name => options['name'],
				:domain => "webenabled.net",
				:cpu => options['cpu'],
				:ram => options['ram'],
				:disk => [{'device' => 0, 'diskImage' => {'capacity' => 100 } }],
				:ephemeral_storage => true,
				:os_code => options['image'],
				:datacenter => options['region']
			} if options['provider'] == 'softlayer'
			@opts = {
				:name => options['name'],
				:image_id => options['image'],
				:size_id => options['size'],
				:region_id => options['region'],
				:flavor_id => options['flavor'],
				:ssh_key_ids => options['ssh_key_id']
			} if options['provider'] == 'digitalocean'
			@opts = {
				:name => options['name'],
				:flavor_id => options['flavor'],
				:image_id => options['image'],
				:public_key_path => options['public_key'],
				:private_key_path => options['private_key'],
				:rackspace_region => options['region']
			} if options['provider'] == 'rackspace'
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
			ThorClass.method_option :force, :type => :boolean, :default => false, :desc => "Force action's execution"
		end
	end

	# methods for generic actions
	no_commands do
		def profile_init
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
		end
		def actions_init
			profile_init
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

	desc "list", "list servers"
	OptionsHelper.method_options
	def list
		profile_init
		p @cloud.servers
	end

	desc "start", "start server"
	OptionsHelper.method_options
	def start
		actions_init
		abort "Rackspace doesn't support #{__callee__.to_s} action." if options['provider'] == 'rackspace'
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
		abort "Rackspace doesn't support #{__callee__.to_s} action." if options['provider'] == 'rackspace'
		if @srv.state == "Running" || @srv.state == "active" || @srv.state = "ACTIVE"
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
		if @srv.state == "Running" || @srv.state == "active" || @srv.state = "ACTIVE"
			@srv.reboot
			print "VPS is currently in the restarting process"
			until @srv.state == "Running" || @srv.state == "active" || @srv.state = "ACTIVE"
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
		if ARGV.include? '--force' || @srv.state == "Halted" || @srv.state == "off" || @srv.state == "ACTIVE"
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
