docker-puppetmaster
===================

A resplendently refreshing Docker image for hosting a containerized, self-provisioning Puppet Master.

The latest fad is to [Dockerize](http://i.imgur.com/V8KfCpj.jpg) all the things, so why not run your
Puppet Master in a Docker container? Did we mention that it also runs its own Puppet agent so that you
can provision it alongside everything else you're managing? Yeah. Perfect for use alongside my wondrous
[docker-puppet](https://github.com/rfkrocktk/docker-puppet) project.

## Built on Phusion's Excellent Docker baseimage

Most Docker base images don't include a proper init system, system logging, or simple facilities like SSH.
[Phusion](https://phusion.nl) provides an excellent Docker [baseimage](https://github.com/phusion/baseimage-docker) 
container based on Ubuntu 14.04 LTS which fixes all of these problems. This means that `syslog` works as
planned, `cron` jobs actually run, and you can `ssh` into the machine with a only a dash of extra
[configuration](https://github.com/phusion/baseimage-docker#login-to-the-container-via-ssh).

## Get Started, Right Now

Let's bust this out. Pull down the Docker image:

   $ sudo docker pull rfkrocktk/puppetmaster

Next, let's start up the Puppet Master in a new Docker container:

    $ sudo docker --name ultramaster --hostname ultramaster \
        -v /var/lib/docker/ultramaster/puppet/data:/data rfkrocktk/puppetmaster

This will start up a brand new Puppet Master Docker container, sharing the Puppet Master's `/data` directory
to the host machine at `/var/lib/docker/ultramaster/puppet/data`. This is important so you can drop in your
manifests and modules here.

At this point, you'll probably want to put your Puppet Master behind an nginx proxy, as per the official
recommendations, but if you're like me and you void your warranties, just expose your Puppet Master to
the default port on the host:

    $ sudo docker --name ultramaster --hostname ultramaster \
        -p 8410:8410 -v /var/lib/docker/ultramaster/puppet/data:/data \
        rfkrocktk/puppetmaster

Alternatively, you can connect your other [docker-puppet](https://github.com/rfkrocktk/docker-puppet) containers
together by simply linking the containers. You should really put it behind a proxy though, seriously.

## Adding/Signing Puppet Agents

You're faced with a few options for signing your client certificates. 

### Manual Way

If you'd like to do it manually,
write a Puppet manifest for your Puppet Master which provisions your public SSH key to the Puppet Master
itself so you can simply SSH in and sign certificates as they come in:

    $ puppet cert sign mypuppetcontainer

This isn't ideal, as it's a bit complicated. 

### Elite/Awesome Way

Since you're using shared Docker volumes anyway, you could simply pregenerate your SSL certificates and 
provision them automagically to the Docker volumes in your provisioning of your host machine. This is cool. 
