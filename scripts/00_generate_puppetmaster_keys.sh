#!/bin/bash

# import environment variables
source /etc/container_environment.sh

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
