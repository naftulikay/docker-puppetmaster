# Puppet for Docker Vagrant Box
node 'vagrant-trusty64' {
    # apt
    class { 'apt': }
   
    # docker
    apt::source { 'docker':
        location => "http://get.docker.io/ubuntu",
        key => "36A1D7869245C8950F966E92D8576A8BA88D21E9",
        release => "docker",
        repos => "main",
        include_src => false
    }

    package { 'lxc-docker':
        require => [Apt::Source["docker"]]
    }

    # tools
    package { 'lxc': } # lxc-attach
    package { 'tree': }
    
    # install puppet client in vagrant
    apt::source { 'puppetlabs':
        key      => '4BD6EC30',
        location => 'http://apt.puppetlabs.com',
        repos    => 'main dependencies'
    }

    package { 'puppet':
        ensure  => latest,
        require => [Apt::Source["puppetlabs"]]
    }
}
