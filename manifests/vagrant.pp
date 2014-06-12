# Puppet for Docker Vagrant Box
node 'vagrant-precise64' {
    # apt
    class { 'apt': }
    
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
}
