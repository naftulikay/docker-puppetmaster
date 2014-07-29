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

# Install the nginx configuration and sites
ADD conf/nginx/nginx.conf /etc/nginx/nginx.conf
ADD conf/nginx/puppetmaster-site.conf /etc/nginx/sites-available/puppetmaster
RUN ln -s /etc/nginx/sites-available/puppetmaster /etc/nginx/sites-enabled/puppetmaster

# Move /etc/puppet to /data
RUN cp -r /etc/puppet /data

# Install boot scripts
ADD scripts/00_generate_puppetmaster_keys.sh /etc/my_init.d/
RUN chmod +x /etc/my_init.d/*.sh

# Expose Puppet Master port
EXPOSE 8410

# Data Volume for Manifests, Modules, and Environments
VOLUME ["/data"]

# use baseimage's init system
CMD ["/sbin/my_init"]
