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

    $ ./ucli.rb --provider softlayer --action create --name=my-vps-name --image ubuntu-14.04 --region dallas --ram 2G --cpus 1
    $ ./ucli.rb -p softlayer -a start -n my-vps-name
    $ ./ucli.rb -p softlayer -a reboot -n my-vps-name
    $ ./ucli.rb -p digitalocean -a stop -n my-vps-name
    $ ./ucli.rb -p rackspace -a destroy -n my-vps-name

Run with **--help** option or without any arguments for more info.
