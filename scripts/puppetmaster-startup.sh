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

# set no-daemonize and the master port
puppet_master_args="--no-daemonize --masterport $PUPPETMASTER_TCP_PORT"

# environments should also live in /data
puppet_master_args="$puppet_master_args --environmentpath /data/environments/"

# we want /data to be owned by root
test -d /data || mkdir /data
chown root:root /data

# we want environments to be owned by puppet
test -d /data/environments || mkdir -p /data/environments/production/{manifests,modules}
chown puppet:puppet -R /data/environments /data/environments/production/{manifests,modules}

# we want symlinks into production just because we can
test -L /data/manifests || ln -s /data/environments/production/manifests /data/manifests
chown puppet:puppet /data/manifests

test -L /data/modules || ln -s /data/environments/production/modules /data/modules
chown puppet:puppet /data/modules

# only root can do important things in /data
chmod 7775 /data

# only the puppet user can read/write/execute things in here
chmod 7770 -R /data/environments /data/manifests /data/modules

# start the puppet master
exec /usr/bin/puppet master $puppet_master_args
