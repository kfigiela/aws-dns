#!/bin/bash

# Change dir to npm package directory
cd "$( dirname "${BASH_SOURCE[0]}" )"

echo "Installing pseudo-TLD into DNS resolver (with sudo!)"
sudo sh -c 'echo "nameserver 127.0.0.1\nport 20561" > /etc/resolver/aws'

echo "Installing aws-dns service (no sudo this time)"
[ -f ~/Library/LaunchAgents/aws-dns.plist ] || cp aws-dns.plist ~/Library/LaunchAgents

echo "Please provide AWS credentials and possibly correct the paths"
$EDITOR ~/Library/LaunchAgents/aws-dns.plist

echo "Registering service with launchd"
launchctl load -w ~/Library/LaunchAgents/aws-dns.plist

echo "Done!"
