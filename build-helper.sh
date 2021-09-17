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

# ModSecurity doesn't have packages for ubuntu below 20.04
if [ `lsb_release -is` == "Ubuntu" ]; then
  if [ `lsb_release -rs` != "20.04" ]; then
    git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /usr/local/src/ModSecurity/
    cd /usr/local/src/ModSecurity/
    git submodule init
    git submodule update
    ./build.sh
    ./configure
    make -j4
    make install
    apt-get -f install -y --no-install-recommends libmaxminddb-dev
  fi
fi

# Make read-write copy of source code
mkdir -p /build
cp -a /source-ro /build/source
cd /build/source

# Install build dependencies
mk-build-deps -ir -t "apt-get -o Debug::pkgProblemResolver=yes -y --no-install-recommends"

# Build packages
echo y|debuild -b -uc -us

# Copy packages to output dir with user's permissions
chown -R $USER:$GROUP /build
cp -a /build/*.deb /output/
echo -e "\n"
echo "Contents of output/ after build:"
ls -l /output
