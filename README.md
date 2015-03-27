# ucli

Universal CLI for cloud providers.

# Installation
## Requirements

* **Ruby >= 1.9.2**
* **Bundler**

To install the dependencies, run bundle in the root dir:

    bundle

# Usage

You have to create your own config.yml in the root dir.
This file should contain the following values:

    provider: 'softlayer'
    softlayer_username: 'your_username'
    softlayer_api_key: 'your_api_key'

## Command line arguments examples

    $ ./ucli.rb create vps --provider=softlayer --name=my-vps-name --image=UBUNTU_LATEST --region=dal05 --ram=1024 --cpu=1
    $ ./ucli.rb create vps --config config_example.yml
    $ ./ucli.rb start -p softlayer -n my-vps-name
    $ ./ucli.rb reboot -p softlayer -n my-vps-name
    $ ./ucli.rb stop -p digitalocean -n my-vps-name
    $ ./ucli.rb destroy -p rackspace -n my-vps-name

Run with **--help** option or without any arguments for more info.

## License

Please refer to [LICENSE.md](LICENSE.md).