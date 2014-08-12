#!/usr/bin/env ruby

require 'erb'
require 'facter'
require 'fileutils'

# source the environment
File.readlines("/etc/container_environment.sh").each do |line|
    values = line.match('(?<=export ).+').to_s.split("=")
    ENV[values[0]] = values[1]
end

# setup variables
path                              = ENV.fetch("PATH", "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
puppet_conf_dir                   = "/etc/puppet"
puppet_conf_defaults_dir          = "/usr/lib/puppet/default"
puppet_auth_file                  = "#{puppet_conf_dir}/auth.conf"
puppet_fileserver_file            = "#{puppet_conf_dir}/fileserver.conf"
puppet_conf_file                  = "#{puppet_conf_dir}/puppet.conf"
puppet_environments_dir           = "#{puppet_conf_dir}/environments"
puppet_manifests_dir              = "#{puppet_conf_dir}/manifests"
puppet_modules_dir                = "#{puppet_conf_dir}/modules"
puppet_templates_dir              = "#{puppet_conf_dir}/templates"

puppetmaster_port                 = ENV.fetch("PUPPETMASTER_TCP_PORT", "8140")
puppetmaster_verbose              = ENV.fetch("PUPPETMASTER_VERBOSE", nil)
puppetmaster_debug                = ENV.fetch("PUPPETMASTER_DEBUG", nil)
puppetmaster_environments_enabled = ENV.fetch("PUPPETMASTER_ENVIRONMENTS_ENABLED", nil)

passenger_conf_file      = "/usr/share/puppet/rack/puppetmaster/config.ru" 

fqdn     = Facter.value('fqdn')
hostname = Facter.value('hostname')

passenger_config_template = ERB.new(%{# config.ru for passenger/puppet
$0 = "master"

ENV['PATH'] = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ARGV << "--rack"
ARGV << "--confdir" << "/etc/puppet"
ARGV << "--vardir" << "/var/lib/puppet"

<% if puppetmaster_verbose %>ARGV << "--verbose"<% end %>
<% if puppetmaster_debug %>ARGV << "--debug"<% end %>

require 'puppet/util/command_line'

run Puppet::Util::CommandLine.new.execute
}).result(binding)

puppet_config_template = ERB.new(%{[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=$vardir/lib/facter
basemodulepath=$confdir/modules
<% if puppetmaster_environments_enabled %>
environmentpath=$confdir/environments/
<% else %>
manifest=$confdir/manifests/
<% end %>
[master]
masterport = <%= puppetmaster_port %>
ssl_client_header = HTTP_X_CLIENT_S_DN
ssl_client_verify_header = HTTP_X_CLIENT_VERIFY

[agent]
server = <%= hostname %>
masterport = <%= puppetmaster_port %>
}).result(binding)

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
        file.write(puppet_config_template)
    }
end

# if no config.rb, create it with our template
if not File.file?(passenger_conf_file)
    puts "Creating #{passenger_conf_file}..."
    File.open(passenger_conf_file, "w") { |file|
        file.write(passenger_config_template)
    }

    FileUtils.chown("puppet", "puppet", passenger_conf_file)
end

# create all them directories
Dir.mkdir(puppet_environments_dir) unless File.directory?(puppet_environments_dir)
Dir.mkdir(puppet_manifests_dir) unless File.directory?(puppet_manifests_dir)
Dir.mkdir(puppet_modules_dir) unless File.directory?(puppet_modules_dir)
Dir.mkdir(puppet_templates_dir) unless File.directory?(puppet_templates_dir)

# chown recursive puppet_conf_dir to root as is default
FileUtils.chown_R("root", "root", "/etc/puppet")
