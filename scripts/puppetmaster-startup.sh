#!/bin/bash

# load environment variables
source /etc/container_environment.sh

# default puppet master port is 8410
test -z "$PUPPETMASTER_TCP_PORT" && export PUPPETMASTER_TCP_PORT="8410"


# if PUPPETMASTER_VERBOSE, make it so
if [ ! -z "$PUPPETMASTER_VERBOSE" ] ; then
    puppet_master_args="--verbose"
fi

# if PUPPETMASTER_DEBUG, make it so
if [ ! -z "$PUPPETMASTER_DEBUG" ]; then
    puppet_master_args="$puppet_master_args --debug"
fi

# set the configuration directory and no daemonize
puppet_master_args="$puppet_master_args --confdir /data/ --environmentpath /data/environments/ --basemodulepath /data/modules/ --no-daemonize"

# set port
puppet_master_args="$puppet_master_args --masterport $PUPPETMASTER_TCP_PORT"

# if /data/puppet.conf doesn't exist, copy over all of the default configuration
if [ ! -f "/data/puppet.conf" ]; then
    cp -r /etc/puppet/* /data
    rm -fr /data/manifests # not interested in manifests, we're using environments
    rm -fr /data/environments/example_env # not interested
fi

# we want /data to be owned by root
test -d /data || mkdir /data
chown root:root /data

# if there's no production environment, create it
test -d /data/environments/production || mkdir -p /data/environments/production/{manifests,modules}
test -d /data/modules || mkdir /data/modules

# only the puppet user can read/write/execute things in here
chmod 7770 -R /data/environments /data/modules

# we want environments to be owned by puppet
chown puppet:puppet -R /data/environments /data/modules

# only root can do important things in /data
chmod 7775 /data

# start the puppet master
exec /usr/bin/puppet master $puppet_master_args
