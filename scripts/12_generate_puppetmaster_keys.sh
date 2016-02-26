#!/bin/bash -e

# import environment variables
source /etc/container_environment.sh

# default SSL DNS names for certificate generation hostname,fqdn,puppet,puppet.domain
hostname="$(facter hostname)"
domain="$(facter domain)"
fqdn="$(facter fqdn)"

test -z "$PUPPETMASTER_DNS_NAMES" && \
    export PUPPETMASTER_DNS_NAMES="$hostname,$fqdn,puppet,puppet.$domain"

# if there's no certificate yet, generate it
if [ -z "$(puppet cert list -a 2> /dev/null | grep \"$fqdn\")" ]; then 
    puppet cert generate --path "$PATH" --dns_alt_names "$PUPPETMASTER_DNS_NAMES" $fqdn
fi
