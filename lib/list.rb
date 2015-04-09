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

	option :name, :type => :string, :default => false, :aliases => "-n", :desc => "Name of VPS"
	option :provider, :type => :string, :default => "aws", :aliases => "-p", :desc => "Provider of specified VPS"
	option :region, :type => :string, :default => "us-east-1", :aliases => "-r", :desc => "Region of datacenter"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Path to provider's credentials of specified VPS"
	option :all, :type => :boolean, :default => false, :desc => "List all snapshots at specified cloud provider"
	desc "snapshots <profile> <name> <region>", "Lists snapshots at specified cloud provider"
	def snapshots
		profiles_init

		if options['provider'] == 'aws'
			if not File.exist?("/usr/bin/aws")
				puts "No AWS CLI found. Installing..."
				if File.exist?("/usr/bin/apt-get")
				`apt-get update && apt-get -y install awscli`
				elsif File.exist?("/usr/bin/yum")
					`yum -y install curl python`
					`curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"`
					`python get-pip.py`
					`pip install awscli`
					`rm -f get-pip.py`
				else
					abort "Unsupported platform. Exiting."
				end
			else
			end

			if ARGV.include? '--all'
				print `AWS_ACCESS_KEY_ID="#{@profile[options['provider']]['aws_access_key_id']}" \
					AWS_SECRET_ACCESS_KEY="#{@profile[options['provider']]['aws_secret_access_key']}" \
					AWS_DEFAULT_REGION="#{options['region']}" aws ec2 describe-snapshots`
			elsif options['name'] != nil
				owner_ids = JSON.parse eval("`AWS_ACCESS_KEY_ID=\"#{@profile[options['provider']]['aws_access_key_id']}\" \
					AWS_SECRET_ACCESS_KEY=\"#{@profile[options['provider']]['aws_secret_access_key']}\" \
					AWS_DEFAULT_REGION=\"#{options['region']}\" aws ec2 describe-instances --instance-id \"#{options['name']}\"`")
				@owner_id = owner_ids['Reservations'][0]['OwnerId']
				print `AWS_ACCESS_KEY_ID="#{@profile[options['provider']]['aws_access_key_id']}" \
					AWS_SECRET_ACCESS_KEY="#{@profile[options['provider']]['aws_secret_access_key']}" \
					AWS_DEFAULT_REGION="#{options['region']}" aws ec2 describe-snapshots --owner-ids "#{@owner_id}"`
			else
			end
		else
		end
	end

	option :provider, :type => :string, :default => "softlayer", :aliases => "-p", :desc => "Provider for new VPS"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Path to provider's credentials for new VPS"
	desc "directory <name>", "Creates a directory at specified storage provider"
	def directories
		profiles_init
		storages_init

		pp @storage.directories
	end

end
