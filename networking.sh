#!/bin/sh

# Add our local network to pg_hba.conf
(
    for ip in $(ip -4 route show | cut -f1 -d' '| sed "s/default//") $(ip -6 route show | cut -f1 -d' '| sed "s/default//") $POSTGRES_NETWORK
    do
        echo "host    all             all             $ip md5"
    done
) >>/var/lib/postgresql/data/pg_hba.conf
