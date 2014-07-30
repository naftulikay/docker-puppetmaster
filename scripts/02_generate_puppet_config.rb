#!/usr/bin/env ruby

require 'facter'

hostname = Facter.value('hostname')

template = %{[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=$vardir/lib/facter

[master]
ssl_client_header = HTTP_X_CLIENT_S_DN
ssl_client_verify_header = HTTP_X_CLIENT_VERIFY

[agent]
server = #{hostname}
}

File.open("/etc/puppet/puppet.conf", "w") { |file|
    file.write(template)
}
