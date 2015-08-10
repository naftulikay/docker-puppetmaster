# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    # Use Phusion's Ubuntu 12.04 box with support for Docker
    config.vm.box = "phusion-open-ubuntu-14.04-amd64"
    config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box"
    # Set hostname
    config.vm.hostname = "vagrant-trusty64"

    # Configure the VirtualBox Provider
    config.vm.provider :virtualbox do |vb|
        # Give the VM 1GB of RAM
        vb.customize ["modifyvm", :id, "--memory", "1024"]
    end

    # Provisioning with Puppet Standalone 
    config.vm.provision :puppet do |puppet|
        puppet.hiera_config_path = "conf/puppet/hiera.yaml"
        puppet.manifests_path = "manifests"
        puppet.manifest_file  = "vagrant.pp"
        puppet.module_path = "modules"
    end
end
