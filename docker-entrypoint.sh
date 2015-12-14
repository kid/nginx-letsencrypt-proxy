#!/bin/bash

set -e

echo "$@"

if [ "$1" = 'nginx' -a ! -f '/etc/ssl/certs/dhparam.pem' ]; then
  openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 > /bin/null
fi

exec "$@"
