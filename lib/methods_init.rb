def profiles_init
	if ARGV.include? '--profile'
		if File.exist?("#{options['profile']}")
			@profile = YAML.load_file("#{options['profile']}")
		else
			abort "No profiles found. You have to create profiles file with credentials first. Exiting."
		end
	elsif File.exist?("#{ENV['HOME']}/.ucli.yml")
			@profile = YAML.load_file("#{ENV['HOME']}/.ucli.yml")
	else
		abort "No profiles found. You have to create profiles file with credentials first. Exiting."
	end
end
def clouds_init
	@cloud = Fog::Compute.new(provider: @profile[options['provider']]['provider'],
		aws_access_key_id: @profile[options['provider']]['aws_access_key_id'],
		aws_secret_access_key: @profile[options['provider']]['aws_secret_access_key']
		) if options['provider'] == 'aws'
	@cloud = Fog::Compute.new(provider: @profile[options['provider']]['provider'],
		digitalocean_api_key: @profile[options['provider']]['digitalocean_api_key'],
		digitalocean_client_id: @profile[options['provider']]['digitalocean_client_id']
		) if options['provider'] == 'digitalocean'
	@cloud = Fog::Compute.new(provider: @profile[options['provider']]['provider'],
		softlayer_username: @profile[options['provider']]['softlayer_username'],
		softlayer_api_key: @profile[options['provider']]['softlayer_api_key']
		) if options['provider'] == 'softlayer'
	@cloud = Fog::Compute.new(provider: @profile[options['provider']]['provider'],
		rackspace_username: @profile[options['provider']]['rackspace_username'],
		rackspace_api_key: @profile[options['provider']]['rackspace_api_key']
		) if options['provider'] == 'rackspace'
	@cloud = Fog::Compute.new(provider: @profile[options['provider']]['provider'],
		linode_api_key: @profile[options['provider']]['linode_api_key']
		) if options['provider'] == 'linode'
end
def storages_init
	@storage = Fog::Storage.new(
		:provider => @profile[options['provider']]['provider'],
		:aws_access_key_id => @profile[options['provider']]['aws_access_key_id'],
		:aws_secret_access_key => @profile[options['provider']]['aws_secret_access_key']
		) if options['provider'] == 'aws'
end
