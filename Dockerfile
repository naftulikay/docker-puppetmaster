FROM phusion/baseimage:0.9.10
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV HOME /root
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8

# Install tools
RUN apt-get update -q 2 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y wget > /dev/null

# Install Puppet Labs Repository for Trusty, then install puppetmaster
RUN wget -q https://apt.puppetlabs.com/puppetlabs-release-trusty.deb && \
    DEBIAN_FRONTEND=noninteractive dpkg -i puppetlabs-release-trusty.deb > /dev/null \
    && rm puppetlabs-release-trusty.deb && apt-get update -q 2 && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes -q 2 puppetmaster >/dev/null

# Install runit startup script
ADD scripts/puppetmaster-startup.sh /etc/service/puppetmaster/run
RUN chmod +x /etc/service/puppetmaster/run

# Expose configuration, data, and log volumes
VOLUME ["/config", "/data", "/log"]

# Tweak the configuration, move it around, etc.
RUN mv /etc/puppet/* /config && rmdir /etc/puppet && ln -s /config /etc/puppet

# Expose Puppet Master port
EXPOSE 8410

CMD ["/sbin/my_init"]

# cleanup
RUN apt-get remove -y wget > /dev/null  && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
