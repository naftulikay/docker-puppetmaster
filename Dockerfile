FROM phusion/baseimage:0.9.10
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV HOME /root
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8

# Install tools
RUN apt-get update -q 2 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y ca-certificates > /dev/null

# Install Puppet Labs Repository for Trusty
RUN curl -o puppet.deb -s https://apt.puppetlabs.com/puppetlabs-release-trusty.deb && \
    DEBIAN_FRONTEND=noninteractive dpkg -i puppet.deb > /dev/null && \
    rm puppet.deb

# The repository for Puppet Master is installed by rfkrocktk/puppet, so just 
# install puppetmaster.
RUN apt-get update -q 2 && DEBIAN_FRONTEND=noninteractive \
    apt-get install --yes -q 2 puppetmaster puppet >/dev/null

# Install runit startup scripts
ADD scripts/puppet-agent-startup.sh /etc/service/puppet/run
RUN chmod +x /etc/service/puppet/run

ADD scripts/puppetmaster-startup.sh /etc/service/puppetmaster/run
RUN chmod +x /etc/service/puppetmaster/run

# Expose Puppet Master port
EXPOSE 8410

# Data Volume for Manifests, Modules, and Environments
VOLUME ["/data"]

# don't clean apt cache, it breaks things and requires manual user intervention!

# use baseimage's init system
CMD ["/sbin/my_init"]
