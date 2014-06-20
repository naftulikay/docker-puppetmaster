#!/bin/bash

# load environment variables
source /etc/container_environment.sh

# nice variables
hostname="$(facter hostname)"
domain="$(facter domain)"
fqdn="$(facter fqdn)"

# default puppet master port is 8410
test -z "$PUPPETMASTER_TCP_PORT" && export PUPPETMASTER_TCP_PORT="8410"

# default puppet environment is 'production'
test -z "$PUPPET_AGENT_ENVIRONMENT" && export PUPPET_AGENT_ENVIRONMENT="production"

# if PUPPET_AGENT_VERBOSE, make it so
if [ ! -z "$PUPPET_AGENT_VERBOSE" ] ; then
    puppet_agent_args="--verbose"
fi

# if PUPPET_AGENT_DEBUG, make it so
if [ ! -z "$PUPPET_AGENT_DEBUG" ]; then
    puppet_agent_args="$puppet_agent_args --debug"
fi

# setup no daemonize
puppet_agent_args="$puppet_agent_args --no-daemonize"

# connect to the local server listening on PUPPETMASTER_TCP_PORT
puppet_agent_args="$puppet_agent_args --server $hostname --masterport $PUPPETMASTER_TCP_PORT"

# setup the agent environment
puppet_agent_args="$puppet_agent_args --environment $PUPPET_AGENT_ENVIRONMENT"

# wait for the certificate generation
while [ ! -f "/var/lib/puppet/ssl/certs/$fqdn.pem" ]; do
    sleep 5
done

# start the puppet agent in foreground with given arguments
exec puppet agent $puppet_agent_args
