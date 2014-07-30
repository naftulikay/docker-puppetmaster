#!/bin/bash

exec nginx -c /etc/nginx/nginx.conf -g "daemon off;"
