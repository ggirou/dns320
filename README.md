Run debian on DNS320
--------------------

Firmwares and documentations : ftp://ftp.dlink.eu/Products/dns/dns-320/
Wikis : http://dns323.kood.org/dns-320

# Prerequisites

## Build debian bootstrap

    docker-compose up

## USB Key

Format USB to ext3. Minimun 2Gb

# Copy files to `HD_a2`

# Connect with ssh

# Quickly restart DNS320

    curl 'http://<nas_hostname>/cgi-bin/system_mgr.cgi' -H 'Cookie: username=admin' --data 'cmd=cgi_restart'

# Some infos

