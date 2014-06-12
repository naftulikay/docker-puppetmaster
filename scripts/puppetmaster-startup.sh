#!/bin/sh

exec /sbin/setuser puppet /usr/bin/puppet master --no-daemonize
