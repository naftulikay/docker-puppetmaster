FROM rfkrocktk/baseimage:1.1.0
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV HOME /root
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8

# Install tools
RUN apt-get update -q 2 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y apt-transport-https ca-certificates > /dev/null

# Install Phusion Passenger Repository for Passenger/NGINX
ADD conf/apt/passenger.list /etc/apt/sources.list.d/
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
    && chmod 0600 /etc/apt/sources.list.d/passenger.list

# Install Puppet Labs Repository for Trusty
RUN curl -o puppet.deb -s https://apt.puppetlabs.com/puppetlabs-release-trusty.deb && \
    DEBIAN_FRONTEND=noninteractive dpkg -i puppet.deb > /dev/null && \
    rm puppet.deb

# Install puppet, puppetmaster, nginx, and passenger
RUN apt-get update -q 2 && DEBIAN_FRONTEND=noninteractive \
    apt-get install --yes -q 2 puppetmaster puppet nginx-extras passenger >/dev/null

# Move /etc/puppet to /data
RUN cp -r /etc/puppet /data

# Install runit startup scripts
#ADD scripts/puppet-agent-startup.sh /etc/service/puppet/run
#RUN chmod +x /etc/service/puppet/run

#ADD scripts/puppetmaster-startup.sh /etc/service/puppetmaster/run
#RUN chmod +x /etc/service/puppetmaster/run

# Cleanup Apt Cache
# RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose Puppet Master port
EXPOSE 8410

# Data Volume for Manifests, Modules, and Environments
VOLUME ["/data"]

# use baseimage's init system
CMD ["/sbin/my_init"]
