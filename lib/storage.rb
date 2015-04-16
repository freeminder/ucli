class Storage < Thor
	no_commands do
		load 'lib/methods_init.rb'
	end


	option :name, :type => :string, :default => false, :aliases => "-n", :desc => "Name of bucket"
	option :provider, :type => :string, :default => "aws", :aliases => "-p", :desc => "Provider of the specified storage"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Path to provider's credentials for new VPS"
	option :region, :type => :string, :default => "us-east-1", :aliases => "-r", :desc => "Region of datacenter"
	option :create, :type => :boolean, :default => false, :desc => "Create a bucket at Amazon S3"
	option :list, :type => :boolean, :default => false, :desc => "List buckets at Amazon S3"
	option :delete, :type => :boolean, :default => false, :desc => "Delete a bucket at Amazon S3"
	desc "bucket <name>", "Creates S3 bucket at the specified storage provider"
	def bucket
		profiles_init
		storages_init

		if ARGV.include? '--create'
			pp @storage.create_bucket(bucket: options['name'])
		elsif ARGV.include? '--list'
			pp @storage.list_buckets()
		elsif  ARGV.include? '--delete'
			pp @storage.delete_bucket(bucket: options['name'])
		else
		end
	end


	option :filepath, :type => :string, :default => false, :aliases => "-n", :desc => "Path to local file"
	option :remotepath, :type => :string, :default => false, :aliases => "-n", :desc => "Path to remote file(key) at the specified S3 bucket"
	option :bucket, :type => :string, :default => false, :aliases => "-n", :desc => "Bucket's name"
	option :provider, :type => :string, :default => "aws", :aliases => "-p", :desc => "Provider of the specified storage"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Path to provider's credentials for new VPS"
	option :region, :type => :string, :default => "us-east-1", :aliases => "-r", :desc => "Region of datacenter"
	desc "upload <filename> <bucket>", "Uploads a file at the specified storage provider"
	def download
		profiles_init
		storages_init

		begin
			resp = @storage.get_object({
				bucket: options['bucket'],
				key: options['remotepath'] },
				target: options['filepath'])
		rescue Exception => e
			abort "Error: #{e.message}"
		else
			puts "File was downloaded as #{options['remotepath']}."
		end
	end


	option :filepath, :type => :string, :default => false, :aliases => "-n", :desc => "Path to local file"
	option :remotepath, :type => :string, :default => false, :aliases => "-n", :desc => "Path to remote file at the specified S3 bucket"
	option :bucket, :type => :string, :default => false, :aliases => "-n", :desc => "Bucket's name"
	option :provider, :type => :string, :default => "aws", :aliases => "-p", :desc => "Provider of the specified storage"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Path to provider's credentials for new VPS"
	option :region, :type => :string, :default => "us-east-1", :aliases => "-r", :desc => "Region of datacenter"
	desc "upload <filename> <bucket>", "Uploads a file at the specified storage provider"
	def upload
		profiles_init
		storages_init

		begin
			resp = @storage.put_object(
				:bucket => options['bucket'],
				:key => options['remotepath'],
				:body => IO.read(options['filepath']))
		rescue Exception => e
			abort "Error: #{e.message}"
		else
			puts "File was uploaded as #{options['remotepath']} with etag: #{resp['etag']}."
		end
	end


	option :name, :type => :string, :default => false, :aliases => "-n", :desc => "Name of VPS"
	option :provider, :type => :string, :default => "aws", :aliases => "-p", :desc => "Provider of the specified storage"
	option :profile, :type => :string, :default => "#{ENV['HOME']}/.ucli.yml", :desc => "Path to provider's credentials for new VPS"
	option :aws_default_creds, :type => :boolean, :default => false, :desc => "Use default AWS credentials from ~/.aws/config"
	option :region, :type => :string, :default => "us-east-1", :aliases => "-r", :desc => "Region of datacenter"
	option :create, :type => :boolean, :default => false, :desc => "Create snapshot at the specified provider"
	option :delete, :type => :string, :default => false, :desc => "Delete snapshot at the specified provider"
	option :copy, :type => :string, :default => false, :desc => "Make a copy of snapshot"
	option :list, :type => :boolean, :default => false, :desc => "List snapshots for the specified instance"
	option :all, :type => :boolean, :default => false, :desc => "List all snapshots at the specified cloud provider"
	desc "snapshot <name>", "Snapshots a volume of instance at the specified provider"
	def snapshot
		profiles_init
		storages_init

		if options['provider'] == 'aws'
			# create snapshot
			if ARGV.include? '--create'
				begin
					resp = @ec2.describe_instances(instance_ids: [options['name']])
					@volume_id = resp['reservations'][0]['instances'][0]['block_device_mappings'][0]['ebs']['volume_id']
					resp = @ec2.create_snapshot(volume_id: @volume_id)
					@snapshot_id = resp['snapshot_id']
				rescue Exception => e
					abort "Error: the specified instance id was not found." if e.inspect.include? "InvalidInstanceIDNotFound"
				else
					puts "Snapshot id #{@snapshot_id} has been created."
				end

			# copy snapshot
			elsif ARGV.include? '--copy'
				begin
					@snapshot_id = options['copy']
					resp = @ec2.copy_snapshot(
						source_region: options['region'],
						source_snapshot_id: @snapshot_id,
						destination_region: options['region']
					)
					error_resp = @ec2.describe_snapshots(snapshot_ids: [@snapshot_id])
				rescue Exception => e
					abort "Error: #{e.message}"
				else
					puts "Snapshot id #{@snapshot_id} has been copied as id #{resp['snapshot_id']}."
				end

			# list snapshots for the specified instance
			elsif ARGV.include? '--list' and options['name'] != nil
				begin
					owner_ids = @ec2.describe_instances(instance_ids: [options['name']])
					@owner_id = owner_ids['reservations'][0]['owner_id']
					resp = @ec2.describe_snapshots(owner_ids: [@owner_id])
				rescue Exception => e
					abort "Error: the specified instance id was not found." if e.inspect.include? "InvalidInstanceIDNotFound"
				else
					pp resp
				end

			# list all snapshots
			elsif ARGV.include? '--all' or options['name'] == nil
				pp @ec2.describe_snapshots

			# delete the specified snapshot
			elsif ARGV.include? '--delete' and options['delete'] != nil
				begin
					@snapshot_id = options['delete']
					resp = @ec2.delete_snapshot(snapshot_id: @snapshot_id)
				rescue Exception => e
					abort "Error: the specified snapshot id was not found." if e.inspect.include? "InvalidSnapshotNotFound"
				else
					puts "Snapshot id #{@snapshot_id} has been deleted."
				end

			else
			end


		elsif options['provider'] == 'softlayer'
			puts "Softlayer backup work here"
		else
		end
	end

end