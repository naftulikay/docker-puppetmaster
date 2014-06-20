FROM rfkrocktk/puppet:1.0.1
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV HOME /root
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8

# The repository for Puppet Master is installed by rfkrocktk/puppet, so just 
# install puppetmaster.
RUN apt-get update -q 2 && DEBIAN_FRONTEND=noninteractive \
    apt-get install --yes -q 2 puppetmaster >/dev/null

# Install runit startup script
ADD scripts/puppetmaster-startup.sh /etc/service/puppetmaster/run
RUN chmod +x /etc/service/puppetmaster/run

# Expose Puppet Master port
EXPOSE 8410

# Data Volume for Manifests, Modules, and Environments
VOLUME ["/data"]

# cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/sbin/my_init"]
