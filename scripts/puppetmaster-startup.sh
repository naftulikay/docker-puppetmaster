#!/bin/bash

# load environment variables
source /etc/container_environment.sh

# default puppet master port is 8410
test -z "$PUPPETMASTER_TCP_PORT" && export PUPPETMASTER_TCP_PORT="8410"

# default SSL DNS names for certificate generation hostname,fqdn,puppet,puppet.domain
hostname="$(facter hostname)"
domain="$(facter domain)"
fqdn="$(facter fqdn)"

test -z "$PUPPETMASTER_DNS_NAMES" && \
    export PUPPETMASTER_DNS_NAMES="$hostname,$fqdn,puppet,puppet.$domain"

# if there's no certificate yet, generate it
if [ ! -f "/var/lib/puppet/ssl/certs/$hostname.pem" ]; then 
    puppet cert generate --dns_alt_names "$PUPPETMASTER_DNS_NAMES" $fqdn >/dev/null 2>&1
fi

# if PUPPETMASTER_VERBOSE, make it so
if [ ! -z "$PUPPETMASTER_VERBOSE" ] ; then
    puppet_master_args="--verbose"
fi

# if PUPPETMASTER_DEBUG, make it so
if [ ! -z "$PUPPETMASTER_DEBUG" ]; then
    puppet_master_args="$puppet_master_args --debug"
fi

# set the configuration directory and no daemonize
puppet_master_args="$puppet_master_args --confdir /data/ --environmentpath /data/environments/ --no-daemonize"

# set port
puppet_master_args="$puppet_master_args --masterport $PUPPETMASTER_TCP_PORT"

# if /data/puppet.conf doesn't exist, copy over all of the default configuration
if [ ! -f "/data/puppet.conf" ]; then
    cp -r /etc/puppet/* /data
fi

# we want /data to be owned by root
test -d /data || mkdir /data
chown root:root /data

# only the puppet user can read/write/execute things in here
chmod 7770 -R /data/environments /data/manifests /data/modules

# we want environments to be owned by puppet
chown puppet:puppet -R /data/environments /data/manifests /data/modules

# only root can do important things in /data
chmod 7775 /data

# start the puppet master
exec /usr/bin/puppet master $puppet_master_args
