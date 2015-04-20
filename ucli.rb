#!/usr/bin/env ruby

require 'fog'
require 'thor'
require 'yaml'
require 'pp'
# require_relative 'lib/methods_init'

# class for create action's subcommands
load 'lib/create.rb'

# class for list action's subcommands
load 'lib/list.rb'

# class for storage action's subcommands
load 'lib/storage.rb'

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
		load 'lib/methods_init.rb'
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
		abort "Rackspace doesn't support #{__callee__.to_s} action." if options['provider'] == 'rackspace'
		if @srv_state == "Halted"
			@srv.start if options['provider'] != 'linode'
			@srv.boot if options['provider'] == 'linode'
			print "VPS is currently in the booting process"
			until @srv_state == "Running"
				print "."
				sleep 3
				actions_init
			end
			print "\n"
			puts "VPS has been started"
		elsif @srv_state == "Running"
			puts "VPS already started."
		else
			puts "Can't start VPS. Please check that VPS is in halted state."
		end
		vps_status
	end

	desc "stop" ,"stop server"
	OptionsHelper.method_options
	def stop
		actions_init
		abort "Rackspace doesn't support #{__callee__.to_s} action." if options['provider'] == 'rackspace'
		if @srv_state == "Running"
			@srv.stop if options['provider'] != 'linode'
			@srv.shutdown if options['provider'] == 'linode'
			print "VPS is currently in the shutting down process"
			until @srv_state == "Halted"
				print "."
				sleep 3
				actions_init
			end
			print "\n"
			puts "VPS has been stopped"
		elsif @srv_state == "Halted"
			puts "VPS already stopped."
		else
			puts "Can't stop VPS. Please check that VPS is in running state."
		end
		vps_status
	end

	desc "reboot" ,"reboot server"
	OptionsHelper.method_options
	def reboot
		actions_init
		if @srv_state == "Running"
			@srv.reboot
			print "VPS is currently in the restarting process"
			until @srv_state == "Running"
				print "."
				sleep 3
				actions_init
			end
			print "\n"
			puts "VPS has been restarted"
		else
			puts "Can't reboot VPS. Please check that VPS is in running state."
		end
		vps_status
	end

	desc "destroy" ,"destroy server"
	OptionsHelper.method_options
	def destroy
		actions_init
		if ARGV.include? '--force' or @srv_state == "Halted"
			@srv.destroy
			print "VPS is currently in the destroying process"
			until @vps_status == "No VPS found with this name. Exiting." or @srv_state == "terminated"
				print "."
				sleep 3
				@vps_status = `#{$0} status -n #{@vps_name} --profile #{options['profile']} --provider #{options['provider']} 2>&1`.chomp
			end
			print "\n"
			puts "VPS has been destroyed"
		else
			puts "Can't destroy VPS. Please check that VPS is in halted state or use --force."
			p @srv_state
			vps_status
		end
	end

	# create action calls Create class with subcommands
	desc "create SUBCOMMAND ...ARGS", "create vps, directory or backup"
	subcommand "create", Create

	# list action calls List class with subcommands
	desc "list SUBCOMMAND ...ARGS", "list vps, images or flavors"
	subcommand "list", List

	# storage action calls Storage class with subcommands
	desc "storage SUBCOMMAND ...ARGS", "snapshot volume of instance, download or upload a file"
	subcommand "storage", Storage

end


ThorClass.start
