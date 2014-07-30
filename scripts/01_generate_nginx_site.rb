#!/usr/bin/env ruby

require 'facter'

fqdn = Facter.value('fqdn')
hostname = Facter.value('hostname')
domain = Facter.value('domain')

template = %{# puppetmaster nginx config

server {
    listen 8140 ssl default_server;
    server_name puppet puppet.#{domain} #{hostname} #{fqdn};

    passenger_enabled on;
    passenger_set_cgi_param    HTTP_X_CLIENT_S_DN $ssl_client_s_dn; 
    passenger_set_cgi_param    HTTP_X_CLIENT_VERIFY $ssl_client_verify; 

    access_log                 /var/log/nginx/puppet_access.log;
    error_log                  /var/log/nginx/puppet_error.log;

    root                       /usr/share/puppet/rack/puppetmaster/public;
    
    ssl_certificate            /var/lib/puppet/ssl/certs/#{fqdn}.pem;
    ssl_certificate_key        /var/lib/puppet/ssl/private_keys/#{fqdn}.pem;
        
    # ssl hardening - https://j.mp/1qiXFeW
    ssl_prefer_server_ciphers  on;
    ssl_protocols              TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers                ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS;

    ssl_crl                    /var/lib/puppet/ssl/ca/ca_crl.pem;
    ssl_client_certificate     /var/lib/puppet/ssl/certs/ca.pem;

    ssl_verify_client          optional;
    ssl_verify_depth           1;
}}

File.open("/etc/nginx/sites-available/puppetmaster", "w") { |file|
    file.write(template)
}
