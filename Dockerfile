FROM phusion/baseimage:0.9.18
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV HOME /root
ENV LANG en_US.UTF-8
ENV PUPPET_VERSION=3.8.6-1puppetlabs1
ENV IMAGE_RELEASE=3
RUN locale-gen en_US.UTF-8

# Fixes Docker Automated Build problem
RUN ln -s -f /bin/true /usr/bin/chfn

# Install tools
RUN apt-get update -q 2 && DEBIAN_FRONTEND=noninteractive \
    apt-get upgrade -y > /dev/null && \
    apt-get install -y apt-transport-https ca-certificates > /dev/null

# Install Phusion Passenger Repository for Passenger/NGINX
ADD conf/apt/passenger.list /etc/apt/sources.list.d/
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 \
    && chmod 0600 /etc/apt/sources.list.d/passenger.list

# Install Puppet Labs Repository for Trusty
RUN curl -o puppet.deb -s https://apt.puppetlabs.com/puppetlabs-release-trusty.deb && \
    DEBIAN_FRONTEND=noninteractive dpkg -i puppet.deb > /dev/null && \
    rm puppet.deb

# Install puppet, puppetmaster, nginx, and passenger
RUN apt-get update -q 2 && DEBIAN_FRONTEND=noninteractive \
    apt-get install --yes -q 2 puppetmaster=$PUPPET_VERSION puppet=$PUPPET_VERSION \
        nginx-extras passenger >/dev/null

# Install the nginx configuration and sites
ADD conf/nginx/nginx.conf /etc/nginx/nginx.conf
RUN ln -s /etc/nginx/sites-available/puppetmaster /etc/nginx/sites-enabled/puppetmaster \
    && rm /etc/nginx/sites-enabled/default

# Install the Puppet Master's rack server
RUN mkdir -p /usr/share/puppet/rack/puppetmaster/tmp /usr/share/puppet/rack/puppetmaster/public \ 
    && chown puppet:puppet -R /usr/share/puppet/rack/puppetmaster

# Backup the Puppet config files, we'll regenerate them on boot if they're not present
RUN mkdir -p /usr/lib/puppet/default \
    && find /etc/puppet -maxdepth 1 -type f -iname "*.conf" -exec mv {} /usr/lib/puppet/default \; \
    && cp /usr/share/puppet/ext/rack/config.ru /usr/lib/puppet/default 

# Install boot scripts
ADD scripts/10_generate_puppet_config.rb /etc/my_init.d/
ADD scripts/11_generate_nginx_site.rb /etc/my_init.d/
ADD scripts/12_generate_puppetmaster_keys.sh /etc/my_init.d/
ADD scripts/13_add_puppet_cron.sh /etc/my_init.d/
RUN chmod +x /etc/my_init.d/*

# Install Puppet Agent script
ADD scripts/run-puppet-agent.sh /sbin/run-puppet-agent
RUN chmod +x /sbin/run-puppet-agent

# Install runit scripts
ADD scripts/nginx-startup.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

# Expose Puppet Master port
EXPOSE 8140

# use baseimage's init system
CMD ["/sbin/my_init"]
