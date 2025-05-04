#!/bin/bash
set -e

# Create necessary directories if they don't exist
mkdir -p /var/run/smokeping
mkdir -p /opt/smokeping/var/cache
mkdir -p /opt/smokeping/var/images
mkdir -p /opt/smokeping/etc

# Check if config files exist, if not, create defaults
if [ ! -f /opt/smokeping/etc/config ]; then
    echo "No config file found, creating default config..."
    cat > /opt/smokeping/etc/config << 'EOF'
*** General ***

owner    = Smokeping Admin
contact  = admin@example.com
mailhost = localhost
sendmail = /usr/sbin/sendmail
imgcache = /opt/smokeping/var/cache
imgurl   = cache
datadir  = /opt/smokeping/var
piddir   = /var/run/smokeping
cgiurl   = http://localhost/smokeping.cgi

*** Alerts ***
to = alertee@example.com
from = smokealert@example.com

*** Database ***

step     = 300
pings    = 20

# Set RRD data directory
RAWMODE  = yes
NORRDTOOL = no

*** Presentation ***

template = /opt/smokeping/etc/basepage.html
htmltitle = Smokeping Dashboard

*** Probes ***

+ FPing
binary = /usr/bin/fping
step = 300
pings = 20
timeout = 500
packetsize = 500

*** Targets ***

probe = FPing

menu = Top
title = Network Latency Monitoring
remark = Welcome to the Smokeping Docker container.

@include /opt/smokeping/etc/targets
EOF
fi

if [ ! -f /opt/smokeping/etc/targets ]; then
    echo "No targets file found, creating default targets..."
    cat > /opt/smokeping/etc/targets << 'EOF'
+ Local
menu = Local Network
title = Local Network

++ LocalMachine
menu = Local Machine
title = This Machine
host = localhost

+ Internet
menu = Internet
title = Internet Connectivity

++ GoogleDNS
menu = Google DNS
title = Google DNS
host = 8.8.8.8

++ CloudflareDNS
menu = Cloudflare DNS
title = Cloudflare DNS
host = 1.1.1.1
EOF
fi

# Set permissions
chown -R www-data:www-data /opt/smokeping/var
chown -R www-data:www-data /var/run/smokeping
chmod -R 755 /opt/smokeping/var

# Initialize Smokeping if first run
if [ ! -f /opt/smokeping/var/.initialized ]; then
    echo "Initializing Smokeping..."
    # Create the RRD files
    /opt/smokeping/bin/smokeping --config=/opt/smokeping/etc/config --init
    touch /opt/smokeping/var/.initialized
fi

# Start supervisord
exec "$@"