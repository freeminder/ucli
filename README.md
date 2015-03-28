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

    digitalocean: "Fog::Compute.new(provider: 'DigitalOcean', digitalocean_api_key: 'your_api_key', digitalocean_client_id: 'your_client_id')"
    softlayer: "Fog::Compute.new(provider: 'softlayer', softlayer_username: 'your_username', softlayer_api_key: 'your_api_key')"

## Command line arguments examples

    $ ./ucli.rb create vps --provider=softlayer --name=my-vps-name --image=UBUNTU_LATEST --region=dal05 --ram=1024 --cpu=1
    $ ./ucli.rb create vps --provider=softlayer --profile profiles.yml --config config_example.yml
    $ ./ucli.rb start -n my-vps-name -p softlayer --profile profiles.yml
    $ ./ucli.rb reboot -n my-vps-name -p softlayer
    $ ./ucli.rb stop -n my-vps-name -p digitalocean
    $ ./ucli.rb destroy -n my-vps-name -p rackspace

Please note to omit '=' when calling --profile and --config arguments.
Run with **--help** option or without any arguments for more info.

## License

Please refer to [LICENSE.md](LICENSE.md).