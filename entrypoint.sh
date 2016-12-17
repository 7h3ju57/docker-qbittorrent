#!/bin/sh -e

# Default configuration file
if [ ! -f /config/qBittorrent.conf ]
then
	cp /default/qBittorrent.conf /config/qBittorrent.conf
fi

# Allow groups to change files.
umask 002

if [ "$@" == "run" ]
then
  exec /usr/bin/supervisord -n -c /etc/supervisord.conf
else
  exec "$@"
fi
