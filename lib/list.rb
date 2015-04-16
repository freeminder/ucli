class List < Thor
	no_commands do
		load 'lib/methods_init.rb'
	end

	option :provider, :type => :string, :default => "softlayer", :aliases => "-p", :desc => "Provider of specified VPS"
	option :region, :type => :string, :default => 3, :aliases => "-r", :desc => "Region of datacenter"
	option :image, :type => :string, :default => 9801950, :aliases => "-i", :desc => "Image of Linux distro"
	option :flavor, :type => :string, :default => 66, :aliases => "-f", :desc => "Flavor ID"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Path to provider's credentials of specified VPS"
	desc "vps <provider> <profile> <name> <region>", "Lists VPS at specified cloud provider"
	def vps
		profiles_init
		clouds_init

		pp @cloud.servers
	end

	option :provider, :type => :string, :default => "softlayer", :aliases => "-p", :desc => "Provider for new VPS"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Path to provider's credentials for new VPS"
	option :region, :type => :string, :default => "us-east-1", :aliases => "-r", :desc => "Region of datacenter"
	option :aws_default_creds, :type => :boolean, :default => false, :desc => "Use default AWS credentials from ~/.aws/config"
	desc "directory <name>", "Creates a directory at specified storage provider"
	def images
		profiles_init
		require 'aws-sdk'

		if File.exist?("#{ENV['HOME']}/.aws/config") and ARGV.include? '--aws_default_creds'
			Aws.config.update({
				region: options['region'],
				credentials: Aws::SharedCredentials.new(:path => "#{ENV['HOME']}/.aws/config", :profile_name => "default") })
		else
			Aws.config.update({
				region: options['region'],
				credentials: Aws::Credentials.new(@profile[options['provider']]['aws_access_key_id'], @profile[options['provider']]['aws_secret_access_key']) })
		end
		@ec2 = Aws::EC2::Client.new

		resp = @ec2.describe_images
		pp resp
	end

end
