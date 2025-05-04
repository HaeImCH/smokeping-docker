#!/bin/bash
set -e

# Create necessary directories if they don't exist
mkdir -p /var/run/smokeping
mkdir -p /opt/smokeping/var/cache
mkdir -p /opt/smokeping/var/images
chown -R www-data:www-data /opt/smokeping/var
chown -R www-data:www-data /var/run/smokeping

# Initialize Smokeping if first run
if [ ! -f /opt/smokeping/var/.initialized ]; then
    echo "Initializing Smokeping..."
    # Create the RRD files
    /opt/smokeping/bin/smokeping --config=/opt/smokeping/etc/config --init
    touch /opt/smokeping/var/.initialized
fi

# Make sure permissions are correct
chown -R www-data:www-data /opt/smokeping/var
chmod -R 755 /opt/smokeping/var

# Start supervisord
exec "$@"