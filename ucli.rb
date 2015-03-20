#!/usr/bin/env ruby
require 'fog/softlayer'
require 'yaml'
config = YAML.load_file('config.yml')


@sl = Fog::Compute.new(provider: config['provider'], softlayer_username: config['softlayer_username'], softlayer_api_key: config['softlayer_api_key'])
# p @sl.servers

server = @sl.servers.get(8538689)
p "Name: ", server.name # => 'hostname.example.com'
p "Create at: ", server.created_at # => DateTime the server was created
p "State: ", server.state # => 'Running', 'Stopped', 'Terminated', etc.
p "Tags: ", server.tags

# server.start if server.state == "Halted" && server.ready == true
# p server.state # "Running"
