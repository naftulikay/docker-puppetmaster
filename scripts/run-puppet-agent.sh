#!/bin/bash -e

# load environment variables
source /etc/container_environment.sh

puppet_agent_args="-l syslog -o --no-daemonize --waitforcert 120"

# if there is a puppet environment defined, append the environment parameter
if [ ! -z "$PUPPET_AGENT_ENVIRONMENT" ]; then
    puppet_agent_args="$puppet_agent_args --environment $PUPPET_AGENT_ENVIRONMENT"
fi

# if they want verbose
if [ ! -z "$PUPPET_AGENT_VERBOSE" ]; then
    puppet_agent_args="$puppet_agent_args --verbose"
fi

# if they want debug
if [ ! -z "$PUPPET_AGENT_DEBUG" ]; then
    puppet_agent_args="$puppet_agent_args --debug"
fi

# run the puppet agent if it's not already running
pgrep -f "/usr/bin/puppet agent" >/dev/null || /usr/bin/puppet agent $puppet_agent_args
