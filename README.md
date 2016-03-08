docker-puppetmaster
===================

A resplendently refreshing Docker image for hosting a containerized, self-provisioning Puppet Master,
served by NGINX and Passenger. The current version is 3.8.6-2.

The latest fad is to [Dockerize](http://i.imgur.com/V8KfCpj.jpg) all the things, so why not run your
Puppet Master in a Docker container? Did we mention that it also runs its own Puppet agent so that you
can provision it alongside everything else you're managing? Yeah. Perfect for use alongside the wondrous
[docker-puppet](https://github.com/rfkrocktk/docker-puppet) project.

## Built on Phusion's Excellent Docker baseimage

Most Docker base images don't include a proper init system, system logging, or simple facilities like SSH.
[Phusion](https://phusion.nl) provides an excellent Docker [baseimage](https://github.com/phusion/baseimage-docker) 
container based on Ubuntu 14.04 LTS which fixes all of these problems. This means that `syslog` works as
planned, `cron` jobs actually run, and you can `ssh` into the machine with a only a dash of extra
[configuration](https://github.com/phusion/baseimage-docker#login-to-the-container-via-ssh).

## ...And Enhanced By Our Own baseimage

Phusion's baseimage provides a few ways of entering your system, namely SSH and `nsenter`. However, there's no 
easy way to add SSH keys, and `nsenter` requires installation of another package. Therefore, we've created our own [baseimage](https://github.com/rfkrocktk/docker-baseimage) built off of Phusion's baseimage which allows you to 
easily add SSH keys to your Docker instance by mounting `/root/.ssh/authorized_keys.d` and editing the `authorized_keys` file it contains or even just specifying SSH keys in an environment variable like `-e SSH_KEYS="$(cat ~/.ssh/authorized_keys)"`.

## Get Started, Right Now

Let's bust this out. Pull down the Docker image:

    $ sudo docker pull rfkrocktk/puppetmaster

Next, let's start up the Puppet Master in a new Docker container:

    $ sudo docker run -d --name ultramaster --hostname ultramaster \
        -v /host/ultramaster-ssh-keys:/root/.ssh/authorized_keys.d \
        -v /host/ultramaster-manifests:/etc/puppet/manifests \
        -v /host/ultramaster-modules:/etc/puppet/modules \
        rfkrocktk/puppetmaster

This will start up a brand new Puppet Master, binding the Puppet manifests and modules directories to local paths on your host machine. Open up `/host/ultramaster-manifests/ultramaster.pp` and add the following:

    node "ultramaster" {
      file { 'proof':
        path    => "/proof",
        ensure  => present,
        content => "it works"
      }
    }

The next time the local Puppet Agent runs, (on the first and thirtieth minute of every hour by default, is customizable), it will create a file `/proof` with the contents `it works`. Let's test that.

First, obtain your Puppet Master's IP address using the following command:

    $ sudo docker inspect -f "{{.NetworkSettings.IPAddress}}" ultramaster
    172.17.0.1

Next, add your SSH key to the Puppet Master's `authorized_keys` file:

    $ cat ~/.ssh/authorized_keys | sudo tee /host/ultramaster-ssh-keys/authorized_keys

Finally, SSH into your Puppet Master and check for the existence of the file:

    $ ssh root@172.17.0.1 "test -f /proof && cat /proof"

If you see "it works," well, it works.

## Playing Nice with Others

Convinced? Thought so.

Now, let's add some other agents to the mix. Create a new Docker Puppet Agent:

    $ sudo docker pull rfkrocktk/puppet
    $ sudo docker run -d --expose 8140 --name dockerduck --hostname dockerduck \
        -e PUPPETMASTER_TCP_HOST="ultramaster" \
        --link ultramaster:ultramaster \
        rfkrocktk/puppet

Next, we need to sign `dockerduck`'s Puppet Agent certificate on `ultramaster`. SSH into `ultramaster` and sign the cert:

    $ sudo docker inspect -f "{{.NetworkSettings.IPAddress}}" ultramaster
    172.17.0.1
    $ ssh root@172.17.0.1
    ultramaster $ puppet cert list
    dockerduck.docker.com
    ultramaster $ puppet cert sign dockerduck.docker.com

Now, `dockerduck` will be able to connect to `ultramaster` to be provisioned.

## Configuration

There are a lot of various configuration options exposed as environment variables as well as valuable mount points for Docker volumes to separate the Docker container from ephemeral and configuration data. 

### Volumes

We haven't done too much in the area of highly-customized Docker volume locations, but there are a few
interesting locations which you'll probably want to mount outside of your container to be able to 
automate moar things.

| Internal Location     | Description                                                                                  |
|-----------------------|----------------------------------------------------------------------------------------------|
| `/etc/puppet`         | The Puppet configuration directory. It's probably wiser to _not_ mount this directory as a Docker volume, instead mounting the important subdirectories. |
| `/etc/puppet/manifests` | The directory containing all Puppet manifests, if the Puppet Master is not configured in environments mode. (See `PUPPETMASTER_ENVIRONMENTS_ENABLED`) |
| `/etc/puppet/modules` | The Puppet Master `basemodulepath` where modules are loaded from. Regardless of whether directory environments are enabled, modules will be used from this directory, possibly in addition to an environment's modules. |
| `/etc/puppet/environments` | The Puppet Master `environmentpath` directory. If the Puppet Master has been configured to use directory environments, this is where you'll define your environments and their configuration. (See `PUPPETMASTER_ENVIRONMENTS_ENABLED`)
| `/var/log`            | You know, where the logs are kept and stuff. The Puppet Agent and Master is configured to use syslog for all logging, so you'll see all Puppet logs in `/var/log/syslog`. The NGINX logs will be in `/var/logs/nginx`. |
| `/var/lib/puppet/ssl` | This is where all SSL certificates will be stored as they are generated by the Puppet Master. |
| `/root/.ssh/authorized_keys.d` | As provided by our resplendent [base image](https://github.com/rfkrocktk/docker-baseimage), you can use this directory to add SSH keys to the `authorized_keys` file it contains, allowing you to log in to this Docker instance with your public/private keypair. (See [rfkrocktk/docker-baseimage](https://github.com/rfkrocktk/docker-baseimage) for instructions on how to use this and more details on how it works) |

### Puppet Master Configuration

The Puppet Master provides the following environment variables for initial configuration of the Puppet Master:

| Variable Name           | Required | Description                                                                   |
|-------------------------|----------|-------------------------------------------------------------------------------|
| `PUPPETMASTER_TCP_PORT` | nope     | The master server port to run the Puppet Master on. The default is port 8140. |
| `PUPPETMASTER_DNS_NAMES` | nope | The DNS names for the Puppet Master to listen as. This is a comma delimited list which defaults to `$hostname,$hostname.$domain,puppet,$puppet.$domain`. This will be internally passed to the NGINX site for the Puppet Master and to `puppet cert generate` when creating the Puppet Master's certificate. If you're going to be accessing your Puppet Master outside of the local machine, make sure you add all of your DNS names here. |
| `PUPPETMASTER_ENVIRONMENTS_ENABLED` | nope | Set this environment variable to any value to enable Puppet directory environments. By default, we use the old deprecated manifests directory which a lot of people still use, `/etc/puppet/manifests`. If you pass this value, you must use the Puppet environments directory `/etc/puppet/environments/$ENVIRONMENT/manifests` for your manifests and `/etc/puppet/environments/$ENVIRONMENT/modules` for your modules. The default environment is `production` in this mode. |
| `PUPPETMASTER_VERBOSE` | nope | Set this environment variable to any value to enable verbose logging by the Puppet Master. |
| `PUPPETMASTER_DEBUG` | nope | Set this environment variable to any value to enable debug logging by the Puppet Master. |

### Puppet Agent Configuration

The local Puppet Agent provides the following environment variables for configuration of the Puppet Agent:

| Variable Name | Required | Description |
|---------------|----------|-------------|
| `PUPPET_AGENT_ENVIRONMENT` | nope | The Puppet environment to run the Puppet Agent under. For this value to have any effect `PUPPETMASTER_ENVIRONMENTS_ENABLED` must be defined. If environments are enabled in the Puppet Master and no value is passed here, the default "production" environment will be used. |
| `PUPPET_AGENT_CRON`    | nope | The CRON schedule at which to run the Puppet Agent. The Puppet Agent will _always_ run on system startup, in addition to whatever this value is set to. The default for this value is `0,30 * * * *`, which means that the Puppet Agent will run on boot and on the first and thirtieth minute of every hour. Don't worry, if a Puppet run overlaps another, no bad side-effects will happen; the CRON job checks to see if a Puppet Agent is running before running another one. |
| `PUPPET_AGENT_VERBOSE` | nope | Set this environment variable to any value to enable verbose logging by the Puppet Agent. |
| `PUPPET_AGENT_DEBUG`   | nope | Set this environment variable to any value to enable debug logging by the Puppet Agent. |

### Logging

As mentioned before, both the local Puppet Agent and the Puppet Master are configured to log to `/var/log/syslog`. Additionally, the NGINX server that runs the Puppet Master logs to `/var/log/nginx`. The Puppet Master site logs to `/var/log/nginx/puppet_access.log` and `/var/log/nginx/puppet_error.log`.

## Administration

Any time you make changes to the Puppet Master configuration files, you'll need to restart the Puppet Master in order for the changes to take effect.

You can simply restart NGINX like so:

    sv restart nginx

Alternatively, you can just restart the Passenger app running the Puppet Master like so:

    touch /usr/share/puppet/rack/puppetmaster/tmp/restart.txt

## Security and Performance

As noted above, we use Phusion's APT repository to install (currently) NGINX version 1.6.0 compiled with the latest version of Phusion Passenger for serving the Puppet Master. This is the recommended way of doing things, as the default WEBRick server wasn't designed for high loads.

SSL has been configured on the NGINX site hosting the Puppet Mastor to only use TLSv1, TLSv1.1, and TLSv1.2. Seeing as your Puppet Agents probably all support TLSv1.2, you may wish to disable the older protocols. 

SSL has also been configured to use a hardened cipher list as recommended [here](https://j.mp/1qiXFeW), which is currently:

    ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS

The NGINX master process runs as `root`, but the worker processes run as `www-data`, as is the default for NGINX. It's important that NGINX runs the master process as `root` so it can read SSL certificates and keys and so other processes _may not_ read SSL certificates and keys.

The Puppet Master Passenger application runs as `puppet`. Passenger also runs two processes, `PassengerWatchdog` and `PassengerHelperAgent` as `root`, and a third `PassengerLoggingAgent` as `nobody`.

Security updates last applied at 2016:02:25 17:16:32 -0800, the glibc bug should be patched.

## Versioning

We're using [semantic versioning](http://semver.org), though we're matching our own versions now to the Puppet Master 
version which we're internally pinning to. (if you use docker-puppetmaster version 3.8.3, you're getting a Docker image
with a Puppet Master version of 3.8.3)

This is different than it was before. 
