class Create < Thor
	no_commands do
		load 'lib/methods_init.rb'
	end

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
	option :linode_plan_id, :type => :string, :default => 1, :desc => "Linode's plan ID"
	option :linode_payment_term, :type => :string, :default => 48, :desc => "Linode's payment term ID"
	option :linode_distro_id, :type => :string, :default => 124, :desc => "Linode's distro ID"
	option :linode_disk_label, :type => :string, :default => "NewDisk", :desc => "Linode's disk label"
	option :linode_disk_size, :type => :string, :default => 24576, :desc => "Linode's disk size in MB"
	option :linode_root_password, :type => :string, :default => "Your_r00t_PWD", :desc => "Linode's root password"
	option :linode_kernel_id, :type => :string, :default => 138, :desc => "Linode's kernel ID"
	option :linode_profile_label, :type => :string, :default => "NewProfile", :desc => "Linode's profile label"
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
				:image_id => options['image'],
				:flavor_id => options['flavor'],
				:region_id	=> options['region']
			} if options['provider'] == 'aws'
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
			@opts = {
				:linode_data_center => options['region'],
				:linode_plan_id => options['linode_plan_id'],
				:linode_payment_term => options['linode_payment_term'],
				:linode_distro_id => options['linode_distro_id'],
				:linode_disk_label => options['linode_disk_label'],
				:linode_disk_size => options['linode_disk_size'],
				:linode_root_password => options['linode_root_password'],
				:linode_kernel_id => options['linode_kernel_id'],
				:linode_profile_label => options['linode_profile_label']
			} if options['provider'] == 'linode'
		end

		profiles_init
		clouds_init

		if options['provider'] == 'linode'
			@linode_id = @cloud.linode_create(
				@opts[:linode_data_center],
				@opts[:linode_plan_id],
				@opts[:linode_payment_term])
			@linode_disk_id = @cloud.linode_disk_createfromdistribution(
				@linode_id[:body]['DATA']['LinodeID'],
				@opts[:linode_distro_id],
				@opts[:linode_disk_label],
				@opts[:linode_disk_size],
				@opts[:linode_root_password])
			@cloud.linode_config_create(
				@linode_id[:body]['DATA']['LinodeID'],
				@opts[:linode_kernel_id],
				@opts[:linode_profile_label],
				@linode_disk_id[:body]['DATA']['DiskID'])
			@cloud.servers.get(@linode_id[:body]['DATA']['LinodeID']).boot
		else
			@cloud.servers.create(@opts)
		end

		srv_hash = JSON.parse @cloud.servers.last.to_json
		print "VPS is currently in the provisioning process"
		until @cloud.servers.get(srv_hash["id"]).ready? == true
			print "."
			sleep 3
		end
		print "\n"
		puts "VPS has been created and ready to use"
	end


end
