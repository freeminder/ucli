# ucli

Universal CLI for cloud providers.

# Installation
## Requirements

* **Ruby >= 1.9.2**
* **Bundler**

To install the dependencies, run bundle in the root dir:

    bundle

# Usage

In case of usage with command line arguments for creating vps, you have to create your own profiles file. Default is ~/.ucli.
Example contents of the file:

    aws:
      provider: 'AWS'
      aws_access_key_id: 'your_access_key_id'
      aws_secret_access_key: 'your_secret_access_key'
    digitalocean:
      provider: 'DigitalOcean'
      digitalocean_api_key: 'your_api_key'
      digitalocean_client_id: 'your_client_id'
    softlayer:
      provider: 'Softlayer'
      softlayer_username: 'your_username'
      softlayer_api_key: 'your_api_key'
    rackspace:
      provider: 'Rackspace'
      rackspace_username: 'your_username'
      rackspace_api_key: 'your_api_key'
      rackspace_region: 'iad'
    linode:
      provider: 'Linode'
      linode_api_key: 'your_api_key'


## Command line arguments examples

    $ ./ucli.rb create vps --provider=softlayer --name=my-vps-name --image=UBUNTU_LATEST --region=dal05 --ram=1024 --cpu=1
    $ ./ucli.rb create vps --provider=softlayer --profile profiles.yml --config examples/config_softlayer.yml
    $ ./ucli.rb create vps --profile profiles.yml --provider digitalocean -n test44100 -i 9801950 -s 33 -r 3 -f 66 --ssh_key_id 534374
    $ ./ucli.rb destroy -n test44100 --profile profiles.yml --provider digitalocean --force
    $ ./ucli.rb create vps --profile profiles.yml --provider rackspace -n test31337 -f 2 -i 1a31fdc8-3900-4411-8c08-d8cbf3c9417c -r iad
    $ ./ucli.rb create vps --linode_plan_id 1 -r 2 --linode_root_password Your_r00t_PWD -p linode
    $ ./ucli.rb create vps -p aws -i ami-d05e75b8 -r us-east-1 -f t2.micro
    $ ./ucli.rb start -n my-vps-name -p softlayer --profile profiles.yml
    $ ./ucli.rb reboot -n my-vps-name -p linode
    $ ./ucli.rb stop -n my-vps-name -p digitalocean
    $ ./ucli.rb list vps -p aws

    $ ./ucli.rb storage bucket --create -n bucket21228 -p aws
    $ ./ucli.rb storage bucket --list
    $ ./ucli.rb storage bucket --delete -n bucket21228

    $ ./ucli.rb storage upload -p aws --bucket bucket21228 --filepath README.md --remotepath README.md
    $ ./ucli.rb storage download --bucket bucket21228 --remotepath README.md --filepath README.txt

    $ ./ucli.rb storage snapshot -p aws --create -n my-vps-id
    $ ./ucli.rb storage snapshot -p aws --copy snap-95d94813
    $ ./ucli.rb storage snapshot -p aws --list -n snap-95d94813
    $ ./ucli.rb storage snapshot -p aws --list --all
    $ ./ucli.rb storage snapshot -p aws --delete snap-95d94813



Please note to omit '=' when calling --profile and --config arguments.

Run with **--help** option or without any arguments for more info.

## License

Please refer to [LICENSE.md](LICENSE.md).