#!/usr/bin/env ruby

require 'facter'
require 'fileutils'

puppet_conf_dir          = "/etc/puppet"
puppet_conf_defaults_dir = "/usr/lib/puppet/default"
puppet_auth_file         = "#{puppet_conf_dir}/auth.conf"
puppet_fileserver_file   = "#{puppet_conf_dir}/fileserver.conf"
puppet_conf_file         = "#{puppet_conf_dir}/puppet.conf"
puppet_environments_dir  = "#{puppet_conf_dir}/environments"
puppet_manifests_dir     = "#{puppet_conf_dir}/manifests"
puppet_modules_dir       = "#{puppet_conf_dir}/modules"
puppet_templates_dir     = "#{puppet_conf_dir}/templates"

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

# create the root puppet conf dir, this should already be here
Dir.mkdir(puppet_conf_dir) unless File.directory?(puppet_conf_dir)

# if no auth.conf, create it
FileUtils.cp("#{puppet_conf_defaults_dir}/auth.conf", puppet_conf_dir) unless File.file?(puppet_auth_file)

# if no fileserver.conf, create it
FileUtils.cp("#{puppet_conf_defaults_dir}/fileserver.conf", puppet_conf_dir) unless File.file?(puppet_fileserver_file)

# if no puppet.conf, create it with our template
if not File.file?(puppet_conf_file)
    puts "Creating #{puppet_conf_file}..."
    File.open(puppet_conf_file, "w") { |file|
        file.write(template)
    }
end

# create all them directories
Dir.mkdir(puppet_environments_dir) unless File.directory?(puppet_environments_dir)
Dir.mkdir(puppet_manifests_dir) unless File.directory?(puppet_manifests_dir)
Dir.mkdir(puppet_modules_dir) unless File.directory?(puppet_modules_dir)
Dir.mkdir(puppet_templates_dir) unless File.directory?(puppet_templates_dir)

# chown recursive puppet_conf_dir to root as is default
FileUtils.chown_R("root", "root", "/etc/puppet")
