class Storage < Thor
	no_commands do
		load 'lib/methods_init.rb'
		def restore_snapshot
			# create a volume from the last snapshot
			resp = @ec2.create_volume(
				snapshot_id: @snapshot_id,
				availability_zone: @availability_zone,
			)
			@new_volume_id = resp['volume_id']
			resp = @ec2.create_tags(
				resources: [@new_volume_id],
				tags: [{
						key: "Name",
						value: "Restored volume by uCLI from snapshot #{@snapshot_id}",
			}])
			puts "Volume id #{@new_volume_id} has been created from snapshot id #{@snapshot_id}."

			# shutdown the instance
			clouds_init
			actions_init
			if @srv_state == "Running"
				@srv.stop
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

			# detach /dev/xvda
			resp = @ec2.describe_instances(instance_ids: [@instance_id])
			@volume_id = resp['reservations'][0]['instances'][0]['block_device_mappings'][0]['ebs']['volume_id']
			resp = @ec2.detach_volume(
				volume_id: @volume_id,
				instance_id: @instance_id,
				force: true,
			)
			@volume_state = resp['state']
			until @volume_state == "available" do
				sleep 3
				resp = @ec2.describe_volumes(volume_ids: [@volume_id])
				@volume_state = resp['volumes'][0]['state']
			end
			puts "Volume id #{@volume_id} has been detached."

			# remove an old volume
			@ec2.delete_volume(volume_id: @volume_id)
			puts "Volume id #{@volume_id} has been deleted."

			# attach @volume_id as /dev/xvda
			resp = @ec2.attach_volume(
				volume_id: @new_volume_id,
				instance_id: @instance_id,
				device: "/dev/sda1",
			)
			@volume_state = resp['state']
			until @volume_state == "in-use" do
				sleep 3
				resp = @ec2.describe_volumes(volume_ids: [@new_volume_id])
				@volume_state = resp['volumes'][0]['state']
			end
			puts "Volume id #{@new_volume_id} has been attached as /dev/sda1 to the instance id #{@instance_id}."
		end
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
			@storage.create_bucket(bucket: options['name'])
			puts "Bucket #{options['name']} has been created."
		elsif ARGV.include? '--list'
			pp @storage.list_buckets()
		elsif  ARGV.include? '--delete'
			begin
				@storage.delete_bucket(bucket: options['name'])
			rescue Exception => e
				abort "Error: #{e.message}"
			else
				puts "Bucket #{options['name']} has been deleted."
			end
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
	option :restore, :type => :string, :default => false, :desc => "Restore snapshot at the specified provider"
	option :last, :type => :boolean, :default => false, :desc => "Restore the latest snapshot at the specified provider"
	option :delete, :type => :string, :default => false, :desc => "Delete snapshot at the specified provider"
	option :copy, :type => :string, :default => false, :desc => "Make a copy of snapshot"
	option :list, :type => :boolean, :default => false, :desc => "List snapshots for the specified instance"
	option :all, :type => :boolean, :default => false, :desc => "List all snapshots at the specified cloud provider"
	desc "snapshot <name>", "Snapshots a volume of instance at the specified provider"
	def snapshot
		profiles_init
		storages_init

		if options['provider'] == 'aws'
			# create a snapshot
			if ARGV.include? '--create'
				begin
					resp = @ec2.describe_instances(instance_ids: [options['name']])
					@volume_id = resp['reservations'][0]['instances'][0]['block_device_mappings'][0]['ebs']['volume_id']
					resp = @ec2.create_snapshot(volume_id: @volume_id, description: "Created by uCLI for instance #{options['name']} from volume #{@volume_id}")
					@snapshot_id = resp['snapshot_id']
				rescue Exception => e
					abort "Error: the specified instance id was not found." if e.inspect.include? "InvalidInstanceIDNotFound"
					abort "Error: #{e.message}"
				else
					puts "Snapshot id #{@snapshot_id} has been created."
				end

			# restore a snapshot
			elsif ARGV.include? '--restore' and options['restore'] =~ /snap/i
				begin
					@instance_id = options['name']

					# find the same zone as instance has
					resp = @ec2.describe_instances(instance_ids: [@instance_id])
					@availability_zone = resp['reservations'][0]['instances'][0]['placement']['availability_zone']

					@snapshot_id = options['restore']
					restore_snapshot
				rescue Exception => e
					abort "Error: #{e.message}"
				else
					puts "Snapshot has been restored as a volume id #{@new_volume_id}."
				end

			# restore the latest snapshot
			elsif ARGV.include? '--restore' and options['last'] == true
				begin
					@instance_id = options['name']

					# find the same zone as instance has
					resp = @ec2.describe_instances(instance_ids: [@instance_id])
					@availability_zone = resp['reservations'][0]['instances'][0]['placement']['availability_zone']

					# find the last snapshot for specified instance
					resp = @ec2.describe_instances(instance_ids: [@instance_id])
					@volume_id = resp['reservations'][0]['instances'][0]['block_device_mappings'][0]['ebs']['volume_id']
					owner_ids = @ec2.describe_instances(instance_ids: [@instance_id])
					@owner_id = owner_ids['reservations'][0]['owner_id']
					resp = @ec2.describe_snapshots(
						owner_ids: [@owner_id],
						filters: [{
							name: "volume-id",
							values: [@volume_id],
					}])

					# sort snapshots by date
					@dates = Array.new
					resp['snapshots'].each { |s| @dates << s['start_time'] }
					resp['snapshots'].each { |s| @snapshot_id = s['snapshot_id'] if s['start_time'] == @dates.sort.last }
					puts "Found the latest snapshot id #{@snapshot_id}."

					restore_snapshot

					# MethodsInit.new.clouds_init
					# desc "stop" ,"stop server"
					# OptionsHelper.method_options
					# p ThorClass.new.stop
				rescue Exception => e
					abort "Error: #{e.message}"
				else
					puts "Snapshot has been restored as a volume id #{@new_volume_id}."
				end

			# copy a snapshot
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
					abort "Error: #{e.message}"
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