#!/usr/bin/env ruby

require 'facter'

# source the environment
File.readlines("/etc/container_environment.sh").each do |line|
    values = line.match('(?<=export ).+').to_s.split("=")
    ENV[values[0]] = values[1]
end

fqdn = Facter.value('fqdn')
hostname = Facter.value('hostname')
domain = Facter.value('domain')

puppetmaster_dns_names = ENV.fetch(
    "PUPPETMASTER_DNS_NAMES", "puppet,puppet.#{domain},#{hostname},#{fqdn}").split(",").join(" ")
puppetmaster_port = ENV.fetch("PUPPETMASTER_TCP_PORT", "8140")

template = %{# puppetmaster nginx config

server {
    listen #{puppetmaster_port} ssl default_server;
    server_name #{puppetmaster_dns_names};

    passenger_enabled          on;
    passenger_set_header       X_CLIENT_S_DN $ssl_client_s_dn; 
    passenger_set_header       X_CLIENT_VERIFY $ssl_client_verify; 

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

if not File.file?("/etc/nginx/sites-available/puppetmaster") 
    File.open("/etc/nginx/sites-available/puppetmaster", "w") { |file|
        file.write(template)
    }
end
