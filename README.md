# ucli

Universal CLI for cloud providers.

# Installation

You have to install the dependencies first. To do that, run bundle in the root dir:

    bundle

# Usage

You have to create your own config.yml in the root dir.
This file should contain the following values:

    provider: 'softlayer'
    softlayer_username: 'your_username'
    softlayer_api_key: 'your_api_key'

## Command line arguments examples

    $ ucli create  vps name=my-vps-name provider=softlayer image=ubuntu-14.04 region=dallas ram=2G cpus=1
    $ ucli start   vps name=my-vps-name provider=softlayer
    $ ucli reboot  vps name=my-vps-name provider=softlayer
    $ ucli stop    vps name=my-vps-name provider=softlayer
    $ ucli destroy vps name=my-vps-name provider=softlayer
