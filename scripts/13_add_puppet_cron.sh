#!/bin/bash

# load environment variables
source /etc/container_environment.sh

# default cron setting is every 30 minutes
test -z "$PUPPET_AGENT_CRON" && export PUPPET_AGENT_CRON="0,30 * * * *"

read -d '' cronscript <<EOF
# Runs the Puppet Agent on a Schedule!
SHELL=/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin

@reboot root /sbin/run-puppet-agent
$PUPPET_AGENT_CRON root /sbin/run-puppet-agent
EOF

echo "$cronscript" > /etc/cron.d/puppet && chmod +x /etc/cron.d/puppet
