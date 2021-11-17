#!/bin/bash

echo " ----------------------------------------------------------------- "
echo "   Check for latest versions of Nginx, SSL libraries and modules   "
echo " ----------------------------------------------------------------- "

INTERACTIVE=false
if [ ! -f "./config" ]; then
  echo "config file not found."
  exit 1;
fi
source ./config

##################################
# Variables
##################################
WORKPWD="${PWD}"
NEEDEDIT=false

NGINX_MAINLINE="$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o 'nginx\-[0-9.]+\.tar[.a-z]*' | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 1 2>&1)"
eval NGINX_MAINLINE_SUB="\$(curl -sL http://nginx.org/packages/mainline/ubuntu/pool/nginx/n/nginx/ 2>&1 | grep -E -o 'nginx_${NGINX_MAINLINE}.*_amd64\.deb*' | awk -F \"nginx_${NGINX_MAINLINE}-\" '/~.*_amd64.deb.>/ {print \$2}' | sed -e 's|~.*_amd64\.deb.>||g' | head -n 1 2>&1)"
NGINX_STABLE="$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o 'nginx\-[0-9.]+\.tar[.a-z]*' | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 2 | grep 1.20 2>&1)"
eval NGINX_STABLE_SUB="\$(curl -sL http://nginx.org/packages/ubuntu/pool/nginx/n/nginx/ 2>&1 | grep -E -o 'nginx_${NGINX_STABLE}.*_amd64\.deb*' | awk -F \"nginx_${NGINX_STABLE}-\" '/~.*_amd64.deb.>/ {print \$2}' | sed -e 's|~.*_amd64\.deb.>||g' | head -n 1 2>&1)"

OPENSSL_1X="$(curl -sL https://www.openssl.org/source/ 2>&1 | grep -E -o 'openssl\-[0-9.]+[a-z]+\.tar[.a-z]*' | awk -F "openssl-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 1 2>&1)"
OPENSSL_3X="$(curl -sL https://www.openssl.org/source/ 2>&1 | grep -E -o 'openssl\-[0-9.]+\.tar[.a-z]*' | awk -F "openssl-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 1 2>&1)"
LIBRESSL_3X="$(curl -sL https://www.libressl.org/ 2>&1 | grep -E -o 'libressl\-[0-9.]+\-relnotes\.txt' | awk -F "libressl-" '/-relnotes.txt$/ {print $2}' | sed -e 's|-relnotes.txt||g' | head -n 1 2>&1)"

PAGESPEED_STABLE="$(curl -sL https://github.com/apache/incubator-pagespeed-ngx/tags 2>&1 | grep -E -o 'v1\.[0-9.]+\-stable[a-zA-Z0-9]*' | head -n 1 2>&1)"
PAGESPEED_BETA="$(curl -sL https://github.com/apache/incubator-pagespeed-ngx/tags 2>&1 | grep -E -o 'v1\.[0-9.]+\-[bR][a-zA-Z0-9]*' | head -n 1 2>&1)"

HEADERS_MORE_TAGS="$(curl -sL https://github.com/openresty/headers-more-nginx-module/tags 2>&1 | grep -E -o 'v[0-9.]+$' | sed -e 's|v||g' | head -n 1 2>&1)"
CACHE_PURGE_TAGS="$(curl -sL https://github.com/FRiCKLE/ngx_cache_purge/tags 2>&1 | grep -E -o '[0-9]\.[0-9]+$' | head -n 1 2>&1)"
VTS_TAGS="$(curl -sL https://github.com/vozlt/nginx-module-vts/tags 2>&1 | grep -E -o 'v[0-9.]+$' | sed -e 's|v||g' | head -n 1 2>&1)"
GEOIP2_TAGS="$(curl -sL https://github.com/leev/ngx_http_geoip2_module/tags 2>&1 | grep -E -o '[0-9]\.[0-9]+$' | head -n 1 2>&1)"
ECHO_TAGS="$(curl -sL https://github.com/openresty/echo-nginx-module/tags 2>&1 | grep -E -o 'v[0-9.]+$' | sed -e 's|v||g' | head -n 1 2>&1)"
MODSEC_TAGS="$(curl -sL https://github.com/SpiderLabs/ModSecurity-nginx/tags 2>&1 | grep -E -o 'v[0-9.]+$' | sed -e 's|v||g' | head -n 1 2>&1)"
NAXSI_TAGS="$(curl -sL https://github.com/nbs-system/naxsi/tags 2>&1 | grep -E -o '[0-9]\.[0-9]+$' | head -n 1 2>&1)"
RTMP_TAGS="$(curl -sL https://github.com/arut/nginx-rtmp-module/tags 2>&1 | grep -E -o 'v[0-9.]+$' | sed -e 's|v||g' | head -n 1 2>&1)"

# Colors
CSI='\033['
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CEND="${CSI}0m"


##################################
# Show results
##################################
echo -e "Nginx mainline : ${NGINX_MAINLINE}-${NGINX_MAINLINE_SUB} "
echo -e "Nginx stable   : ${NGINX_STABLE}-${NGINX_STABLE_SUB} "
if [ "${NGINX_VERSION:2:2}" = "20" ]; then
  echo -ne "Config using stable : "
  if [[ "${NGINX_VERSION}" = "${NGINX_STABLE}" && "${NGINX_STABLE_SUB}" = "${NGINX_SUBVERSION}" ]]; then
    echo -e "${CGREEN}${NGINX_VERSION}-${NGINX_SUBVERSION}${CEND}"
  else
    echo -e "${CRED}${NGINX_VERSION}-${NGINX_SUBVERSION}${CEND}"
    NEEDEDIT=true
  fi
else
  echo -ne "Config using mainline : "
  if [[ "${NGINX_VERSION}" = "${NGINX_MAINLINE}" && "${NGINX_MAINLINE_SUB}" = "${NGINX_SUBVERSION}" ]]; then
    echo -e "${CGREEN}${NGINX_VERSION}-${NGINX_SUBVERSION}${CEND}"
  else
    echo -e "${CRED}${NGINX_VERSION}-${NGINX_SUBVERSION}${CEND}"
    NEEDEDIT=true
  fi
fi
echo -e "\nOpenSSL 1.x series : ${OPENSSL_1X}"
echo -e "OpenSSL 3.x series : ${OPENSSL_3X} (don't use yet)"
echo -e "LibreSSL : ${LIBRESSL_3X}"
if [ "${LATEST_OPENSSL}" = false ]; then
  echo -e "Config using System Default"
else
  if [ "${LIBRESSL}" = false ]; then
    echo -ne "Config using OpenSSL 1.x : "
    if [ "${OPENSSL_1X}" = "${OPENSSL_VERSION}" ]; then
      echo -e "${CGREEN}${OPENSSL_VERSION}${CEND}"
    else
      echo -e "${CRED}${OPENSSL_VERSION}${CEND}"
      NEEDEDIT=true
    fi
  else
    echo -ne "Config using LibreSSL : "
    if [ "${LIBRESSL_3X}"] = "${LIBRESSL_VERSION}" ]; then
      echo -e "${CGREEN}${LIBRESSL_VERSION}${CEND}"
    else
      echo -e "${CRED}${LIBRESSL_VERSION}${CEND}"
      NEEDEDIT=true
    fi
  fi
fi
echo -e "\nPagespeed Stable : ${PAGESPEED_STABLE}"
echo -e "Pagespeed Beta/RC : ${PAGESPEED_BETA} (requires url swapping in the config, comments are present for it.)"
if [ "${PAGESPEED_STABLE}" = "${PAGESPEED_VERSION}" ]; then
  echo -e "Config using Stable : ${CGREEN}${PAGESPEED_VERSION}${CEND}"
elif [ "${PAGESPEED_BETA}" = "${PAGESPEED_VERSION}" ]; then
  echo -e "Config using Beta : ${CGREEN}${PAGESPEED_VERSION}${CEND}"
else
  echo -e "Config using : ${CRED}${PAGESPEED_VERSION}${CEND}"
  NEEDEDIT=true
fi
echo -ne "\nModules:\n"
echo -e "               Latest - Config"
echo -ne "Headers more : "
if [ "${HEADERS_MORE_TAGS}" = "${HEADERS_MORE_VERSION}" ]; then
  echo -e "${HEADERS_MORE_TAGS} - ${CGREEN}${HEADERS_MORE_VERSION}${CEND}"
else
  echo -e "${HEADERS_MORE_TAGS} - ${CRED}${HEADERS_MORE_VERSION}${CEND}"
  NEEDEDIT=true
fi
echo -ne "Cache purge  : "
if [ "${CACHE_PURGE_TAGS}" = "${CACHE_PURGE_VERSION}" ]; then
  echo -e "${CACHE_PURGE_TAGS} - ${CGREEN}${CACHE_PURGE_VERSION}${CEND}"
else
  echo -e "${CACHE_PURGE_TAGS} - ${CRED}${CACHE_PURGE_VERSION}${CEND}"
  NEEDEDIT=true
fi
echo -ne "VTS          : "
if [ "${VTS_TAGS}" = "${VTS_VERSION}" ]; then
  echo -e "${VTS_TAGS} - ${CGREEN}${VTS_VERSION}${CEND}"
else
  echo -e "${VTS_TAGS} - ${CRED}${VTS_VERSION}${CEND}"
  NEEDEDIT=true
fi
echo -ne "GeoIP2       : "
if [ "${GEOIP2_TAGS}" = "${GEOIP2_VERSION}" ]; then
  echo -e "${GEOIP2_TAGS} - ${CGREEN}${GEOIP2_VERSION}${CEND}"
else
  echo -e "${GEOIP2_TAGS} - ${CRED}${GEOIP2_VERSION}${CEND}"
  NEEDEDIT=true
fi
echo -ne "Echo         : "
if [ "${ECHO_TAGS}" = "${ECHO_VERSION}" ]; then
  echo -e "${ECHO_TAGS} - ${CGREEN}${ECHO_VERSION}${CEND}"
else
  echo -e "${ECHO_TAGS} - ${CRED}${ECHO_VERSION}${CEND}"
  NEEDEDIT=true
fi
echo -ne "ModSecurity  : "
if [ "${MODSEC_TAGS}" = "${MODSECURITY_VERSION}" ]; then
  echo -e "${MODSEC_TAGS} - ${CGREEN}${MODSECURITY_VERSION}${CEND}"
else
  echo -e "${MODSEC_TAGS} - ${CRED}${MODSECURITY_VERSION}${CEND}"
  NEEDEDIT=true
fi
echo -ne "Naxsi        : "
if [ "${NAXSI_TAGS}" = "${NAXSI_VERSION}" ]; then
  echo -e "${NAXSI_TAGS} - ${CGREEN}${NAXSI_VERSION}${CEND}"
else
  echo -e "${NAXSI_TAGS} - ${CRED}${NAXSI_VERSION}${CEND}"
  NEEDEDIT=true
fi
echo -ne "RTMP         : "
if [ "${RTMP_TAGS}" = "${RTMP_VERSION}" ]; then
  echo -e "${RTMP_TAGS} - ${CGREEN}${RTMP_VERSION}${CEND}"
else
  echo -e "${RTMP_TAGS} - ${CRED}${RTMP_VERSION}${CEND}"
  NEEDEDIT=true
fi

if [ "${NEEDEDIT}" = true ]; then
  echo -ne "\n\nConfig needs editing to update the versions above in red\n\n"
else
  echo -ne "\n\nConfig containing all the latest versions\n\n"
fi
