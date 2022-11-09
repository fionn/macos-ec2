#!/bin/bash

set -euo pipefail

function vnc {
    defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
    launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
    dscl . -passwd /Users/ec2-user "${password}"
    echo "Configured VNC"
}

function dependencies {
    sudo -u ec2-user brew update -q > /dev/null
    sudo -u ec2-user brew upgrade -q
    echo "Updated and upgraded packages"
}

function main {
    vnc
    dependencies
}

main "$@"
