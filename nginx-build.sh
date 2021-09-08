#!/bin/bash

# Initialize
WORKPWD=${PWD}
echo "Working in ${WORKPWD}"

if [ ! -f "./config" ]; then
  echo "config file not found."
  exit 1;
fi
source ./config


# Fetch sources
if [ ! -d "src" ]; then
  mkdir src
fi
cd src

if [ ! -f "nginx_${NGINX_VERSION}.orig.tar.gz" ]; then
  wget "http://nginx.org/packages/mainline/ubuntu/pool/nginx/n/nginx/nginx_${NGINX_VERSION}.orig.tar.gz"
  if [ $? -ne 0 ]; then
    NGINX_ALT_URL=true
    wget "https://nginx.org/packages/ubuntu/pool/nginx/n/nginx/nginx_${NGINX_VERSION}.orig.tar.gz"
  fi
fi
if [ "${CHECKSUM_CHECKS}" = true ]; then
  echo ${NGINX_ORIG_SHA256} nginx_${NGINX_VERSION}.orig.tar.gz | sha256sum --check
  if [ $? -ne 0 ]; then
    echo "Checksum for nginx_${NGINX_VERSION}.orig.tar.gz did NOT match, aborting with return code $?"
    exit 1;
  fi
fi

if [ ! -f "nginx_${NGINX_VERSION}-1~${DISTRO_NAME}.debian.tar.xz" ]; then
  if [ "${NGINX_ALT_URL}" = true ]; then
    wget "https://nginx.org/packages/ubuntu/pool/nginx/n/nginx/nginx_${NGINX_VERSION}-1~${DISTRO_NAME}.debian.tar.xz"
  else
    wget "http://nginx.org/packages/mainline/ubuntu/pool/nginx/n/nginx/nginx_${NGINX_VERSION}-1~${DISTRO_NAME}.debian.tar.xz"
  fi
fi
if [ "${CHECKSUM_CHECKS}" = true ]; then
  echo ${NGINX_DEB_SHA256} nginx_${NGINX_VERSION}-1~${DISTRO_NAME}.debian.tar.xz | sha256sum --check
  if [ $? -ne 0 ]; then
    echo "Checksum for nginx_${NGINX_VERSION}-1~${DISTRO_NAME}.debian.tar.xz did NOT match, aborting with return code $?"
    exit 1;
  fi
fi

if [ "${LATEST_OPENSSL}" = true ]; then
  if [ ! -f "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
    wget "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
  fi
  if [ "${CHECKSUM_CHECKS}" = true ]; then
    echo ${OPENSSL_SHA256} openssl-${OPENSSL_VERSION}.tar.gz | sha256sum --check
    if [ $? -ne 0 ]; then
      echo "Checksum for openssl-${OPENSSL_VERSION}.tar.gz did NOT match, aborting with return code $?"
      exit 1;
    fi
  fi
fi

if [ "${PAGESPEED}" = true ]; then
  if [ ! -f "${PAGESPEED_VERSION}.tar.gz" ]; then
    wget "https://github.com/apache/incubator-pagespeed-ngx/archive/refs/tags/${PAGESPEED_VERSION}.tar.gz"
  fi
  if [ "${CHECKSUM_CHECKS}" = true ]; then
    echo ${PAGESPEED_SHA256} ${PAGESPEED_VERSION}.tar.gz | sha256sum --check
    if [ $? -ne 0 ]; then
      echo "Checksum for ${PAGESPEED_VERSION}.tar.gz did NOT match, aborting with return code $?"
      exit 1;
    fi
  fi

  if [ ! -f "${PSOL_VERSION}.tar.gz" ]; then
    wget "https://dl.google.com/dl/page-speed/psol/${PSOL_VERSION}.tar.gz"
  fi
  if [ "${CHECKSUM_CHECKS}" = true ]; then
    echo ${PSOL_SHA256} ${PSOL_VERSION}.tar.gz | sha256sum --check
    if [ $? -ne 0 ]; then
      echo "Checksum for ${PSOL}.tar.gz did NOT match, aborting with return code $?"
      exit 1;
    fi
  fi
fi

if [ "${HEADERS_MORE}" = true ]; then
  if [ ! -f "v${HEADERS_MORE_VERSION}.tar.gz" ]; then
    wget "https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v${HEADERS_MORE_VERSION}.tar.gz"
  fi
  if [ "${CHECKSUM_CHECKS}" = true ]; then
    echo ${HEADERS_MORE_SHA256} v${HEADERS_MORE_VERSION}.tar.gz | sha256sum --check
    if [ $? -ne 0 ]; then
      echo "Checksum for v${HEADERS_MORE_VERSION}.tar.gz did NOT match, aborting with return code $?"
      exit 1;
    fi
  fi
fi

if [ "${CACHE_PURGE}" = true ]; then
  if [ ! -f "${CACHE_PURGE_VERSION}.tar.gz" ]; then
    wget "https://github.com/FRiCKLE/ngx_cache_purge/archive/refs/tags/${CACHE_PURGE_VERSION}.tar.gz"
  fi
  if [ "${CHECKSUM_CHECKS}" = true ]; then
    echo ${CACHE_PURGE_SHA256} ${CACHE_PURGE_VERSION}.tar.gz | sha256sum --check
    if [ $? -ne 0 ]; then
      echo "Checksum for ${CACHE_PURGE_VERSION}.tar.gz did NOT match, aborting with return code $?"
      exit 1;
    fi
  fi
fi

if [ "${VTS}" = true ]; then
  if [ ! -f "v${VTS_VERSION}.tar.gz" ]; then
    wget "https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v${VTS_VERSION}.tar.gz"
  fi
  if [ "${CHECKSUM_CHECKS}" = true ]; then
    echo ${VTS_SHA256} v${VTS_VERSION}.tar.gz | sha256sum --check
    if [ $? -ne 0 ]; then
      echo "Checksum for v${VTS_VERSION}.tar.gz did NOT match, aborting with return code $?"
      exit 1;
    fi
  fi
fi

if [ "${GEOIP2}" = true ]; then
  if [ ! -f "${GEOIP2_VERSION}.tar.gz" ]; then
    wget "https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/${GEOIP2_VERSION}.tar.gz"
  fi
  if [ "${CHECKSUM_CHECKS}" = true ]; then
    echo ${GEOIP2_SHA256} ${GEOIP2_VERSION}.tar.gz | sha256sum --check
    if [ $? -ne 0 ]; then
      echo "Checksum for ${GEOIP2_VERSION}.tar.gz did NOT match, aborting with return code $?"
      exit 1;
    fi
  fi
fi

if [ "${ECHO}" = true ]; then
  if [ ! -f "v${ECHO_VERSION}.tar.gz" ]; then
    wget "https://github.com/openresty/echo-nginx-module/archive/refs/tags/v${ECHO_VERSION}.tar.gz"
  fi
  if [ "${CHECKSUM_CHECKS}" = true ]; then
    echo ${ECHO_SHA256} v${ECHO_VERSION}.tar.gz | sha256sum --check
    if [ $? -ne 0 ]; then
      echo "Checksum for v${ECHO_VERSION}.tar.gz did NOT match, aborting with return code $?"
      exit 1;
    fi
  fi
fi

if [ "${MODSECURITY}" = true ]; then
  if [ ! -f "modsecurity-nginx-v${MODSECURITY_VERSION}.tar.gz" ]; then
    wget "https://github.com/SpiderLabs/ModSecurity-nginx/releases/download/v1.0.2/modsecurity-nginx-v${MODSECURITY_VERSION}.tar.gz"
  fi
  if [ "${CHECKSUM_CHECKS}" = true ]; then
    echo ${MODSECURITY_SHA256} modsecurity-nginx-v${MODSECURITY_VERSION}.tar.gz | sha256sum --check
    if [ $? -ne 0 ]; then
      echo "Checksum for modsecurity-nginx-v${MODSECURITY_VERSION}.tar.gz did NOT match, aborting with return code $?"
      exit 1;
    fi
  fi
fi

if [ "${BROTLI}" = true ]; then
  if [ ! -d "ngx_brotli" ]; then
    git clone --recursive ${BROTLI_GITHUB}
    if [ $? -ne 0 ]; then
      echo "Something went wrong while cloning brotli's git repo"
      exit 1;
    fi
    echo "ngx_brotli cloned: OK"
  else
    cd ngx_brotli
    git pull --recurse-submodules
    if [ $? -ne 0 ]; then
      echo "Something went wrong while updating from brotli's git repo"
      exit 1;
    fi
    cd ..
    echo "ngx_brotli update check: OK"
  fi
fi

cd ${WORKPWD}
# exit 0;

# Setup build directory
if [ ! -d "build" ]; then
  mkdir build
else
  rm -Rf build
  mkdir build
fi
cd build

tar -zxf ${WORKPWD}/src/nginx_${NGINX_VERSION}.orig.tar.gz
cd nginx-${NGINX_VERSION}
tar -xf ${WORKPWD}/src/nginx_${NGINX_VERSION}-1~${DISTRO_NAME}.debian.tar.xz
cd debian
sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --with-http_v2_hpack_enc/g" rules
mkdir modules
cd modules
if [ "${LATEST_OPENSSL}" = true ]; then
  tar -zxf ${WORKPWD}/src/openssl-${OPENSSL_VERSION}.tar.gz
  cd ..
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --with-openssl=\"\$(CURDIR)\/debian\/modules\/openssl-${OPENSSL_VERSION}\"/g" rules
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/modules
if [ "${PAGESPEED}" = true ]; then
  tar -zxf ${WORKPWD}/src/${PAGESPEED_VERSION}.tar.gz
  mv incubator-pagespeed-ngx-${PAGESPEED_VERSION:1} ngx_pagespeed
  cd ngx_pagespeed
  cp ${WORKPWD}/src/${PSOL_VERSION}.tar.gz .
  tar -zxf ${WORKPWD}/src/${PSOL_VERSION}.tar.gz
  cd ../..
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --add-module=\"\$(CURDIR)\/debian\/modules\/ngx_pagespeed\"/g" rules
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/modules
if [ "${HEADERS_MORE}" = true ]; then
  tar -zxf ${WORKPWD}/src/v${HEADERS_MORE_VERSION}.tar.gz
  cd ..
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --add-module=\"\$(CURDIR)\/debian\/modules\/headers-more-nginx-module-${HEADERS_MORE_VERSION}\"/g" rules
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/modules
if [ "${CACHE_PURGE}" = true ]; then
  tar -zxf ${WORKPWD}/src/${CACHE_PURGE_VERSION}.tar.gz
  cd ..
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --add-module=\"\$(CURDIR)\/debian\/modules\/ngx_cache_purge-${CACHE_PURGE_VERSION}\"/g" rules
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/modules
if [ "${VTS}" = true ]; then
  tar -zxf ${WORKPWD}/src/v${VTS_VERSION}.tar.gz
  cd ..
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --add-module=\"\$(CURDIR)\/debian\/modules\/nginx-module-vts-${VTS_VERSION}\"/g" rules
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/modules
if [ "${GEOIP2}" = true ]; then
  tar -zxf ${WORKPWD}/src/${GEOIP2_VERSION}.tar.gz
  cd ..
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --add-module=\"\$(CURDIR)\/debian\/modules\/ngx_http_geoip2_module-${GEOIP2_VERSION}\"/g" rules
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/modules
if [ "${ECHO}" = true ]; then
  tar -zxf ${WORKPWD}/src/v${ECHO_VERSION}.tar.gz
  cd ..
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --add-module=\"\$(CURDIR)\/debian\/modules\/echo-nginx-module-${ECHO_VERSION}\"/g" rules
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/modules
if [ "${MODSECURITY}" = true ]; then
  tar -zxf ${WORKPWD}/src/modsecurity-nginx-v${MODSECURITY_VERSION}.tar.gz
  cd ..
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --add-module=\"\$(CURDIR)\/debian\/modules\/modsecurity-nginx-v${MODSECURITY_VERSION}\"/g" rules
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/modules
if [ "${BROTLI}" = true ]; then
  cp -R ${WORKPWD}/src/ngx_brotli/ .
  cd ..
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --add-module=\"\$(CURDIR)\/debian\/modules\/ngx_brotli\"/g" rules
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}
if [ "${LATEST_OPENSSL}" = true ]; then
  pwd
  patch -p0 < ${WORKPWD}/custom/patches/openssl-compile.patch
fi
if [ "${USE_CUSTOM_PATCHES}" = true ]; then
  if [ ! -f ".patchdone" ]; then
    cp ${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6.patch ${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch
    sed -i "s/@CACHEPVER@/${CACHE_PURGE_VERSION}/g" ${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch
    patch -p0 < ${WORKPWD}/custom/patches/nginx-version.patch
    cd debian
    patch -p0 < ${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch
    cd ..
    patch -p1 < ${WORKPWD}/custom/patches/ngx_cloudflare_http2_hpack_1015003.patch
    patch -p1 < ${WORKPWD}/custom/patches/ngx_cloudflare_dynamic_tls_records_1015008.patch
    touch .patchdone
    rm -f ${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch
  fi
fi
cd ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian
echo "/etc/nginx/sites-available" >> nginx.dirs
echo "/etc/nginx/sites-enabled" >> nginx.dirs
echo "/var/cache/nginx/pagespeed" >> nginx.dirs
if [ "${USE_CUSTOM_CONFIGS}" = true ]; then
  echo -en "Inserting Configs..."
  echo "/etc/nginx/conf.d/custom" >> nginx.dirs
  cp -f ${WORKPWD}/custom/configs/nginx.conf ${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/nginx.conf
  mkdir custom
  cp -f ${WORKPWD}/custom/configs/*.conf custom/

#  confs=("fpm-wordpress-cache.conf" "fpm-default.conf")
  for i in "${confs[@]}"
  do
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/$i \$\(INSTALLDIR\)\/etc\/nginx\/conf.d\/custom\/$i" rules
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/$i \$\(INSTALLDIR\)\/etc\/nginx\/conf.d\/custom\/$i" nginx.rules.in
  done

  echo -e "OK"
fi


cd ${WORKPWD}
# exit 0;

# Build the package
if [ ! -d "output" ]; then
  mkdir output
else
  rm -Rf output
  mkdir output
fi

docker build -t docker-deb-builder:${DISTRO_VERSION} -f Dockerfile-ubuntu-${DISTRO_VERSION} .
cd ${WORKPWD}
./docker.sh -i docker-deb-builder:${DISTRO_VERSION} -o output build/nginx-${NGINX_VERSION}
./docker.sh -i docker-deb-builder:${DISTRO_VERSION} -o output -t nginx-${NGINX_VERSION} build/nginx-${NGINX_VERSION}

