#!/bin/bash -e

# This script is executed within the container as root.  It assumes
# that source code with debian packaging files can be found at
# /source-ro and that resulting packages are written to /output after
# succesful build.  These directories are mounted as docker volumes to
# allow files to be exchanged between the host and the container.

# Install extra dependencies that were provided for the build (if any)
#   Note: dpkg can fail due to dependencies, ignore errors, and use
#   apt-get to install those afterwards
[[ -d /dependencies ]] && dpkg -i /dependencies/*.deb || apt-get -f install -y --no-install-recommends

# Test package
apt-get -f install -y --no-install-recommends curl
mkdir -p /tmp
cd /tmp
cp /output/*.deb .
rm *dbg*
apt-get -f install -y --no-install-recommends ./nginx*_amd64.deb
nginx -V
/usr/sbin/nginx -t
/usr/sbin/nginx && sleep 5
curl -s -I http://127.0.0.1
cat /var/log/nginx/error.log
apt-get -y purge nginx

# Copy packages to output dir with user's permissions
echo -e "\n"
echo "Contents of output/ after build:"
ls -l /output
