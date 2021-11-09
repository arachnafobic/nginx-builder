#!/bin/bash

echo " --------------------------------------------------------------------------- "
echo "   Nginx-builder : automated Nginx package creation with additional modules  "
echo " --------------------------------------------------------------------------- "


##################################
# Initialize
##################################
if [[ "${LATEST_OPENSSL}" = true && "${LIBRESSL}" == true ]]; then
  echo "Both Latest OpenSSL and LibreSSL are set to true in the config, this is not possible to run."
  exit 1;
fi

_help() {
  echo ""
  echo "Usage: ./nginx-build.sh <options>"
  echo "By default, Nginx-builder will compile Nginx according to how the config file is setup"
  echo "  Options:"
  echo "       -h, --help ..... display this help"
  echo "       -i, --interactive ....... interactive installation"
  echo ""
  return 0
}

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

package_installed() {
  dpkg -l | grep "ii  $@ " >/dev/null 2>&1
}

fail() {
  echo -ne "[${CRED}FAIL${CEND}]\n\n"
  echo "$1"
  echo "See $output_log for possibly more info."
  echo ""
  exit 1;
}

INTERACTIVE=false
while [ "$#" -gt 0 ]; do
    case "$1" in
    -i | --interactive)
        INTERACTIVE=true
        ;;
    -h | --help)
        _help
        exit 1
        ;;
    *) ;;
    esac
    shift
done

##################################
# Variables
##################################
WORKPWD="${PWD}"
readonly OS_ARCH="$(uname -m)"
NGINX_MAINLINE="$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o 'nginx\-[0-9.]+\.tar[.a-z]*' | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 1 2>&1)"
eval NGINX_MAINLINE_SUB="\$(curl -sL http://nginx.org/packages/mainline/ubuntu/pool/nginx/n/nginx/ 2>&1 | grep -E -o 'nginx_${NGINX_MAINLINE}.*_amd64\.deb*' | awk -F \"nginx_${NGINX_MAINLINE}-\" '/~.*_amd64.deb.>/ {print \$2}' | sed -e 's|~.*_amd64\.deb.>||g' | head -n 1 2>&1)"
NGINX_STABLE="$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o 'nginx\-[0-9.]+\.tar[.a-z]*' | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 2 | grep 1.20 2>&1)"
eval NGINX_STABLE_SUB="\$(curl -sL http://nginx.org/packages/ubuntu/pool/nginx/n/nginx/ 2>&1 | grep -E -o 'nginx_${NGINX_STABLE}.*_amd64\.deb*' | awk -F \"nginx_${NGINX_STABLE}-\" '/~.*_amd64.deb.>/ {print \$2}' | sed -e 's|~.*_amd64\.deb.>||g' | head -n 1 2>&1)"

# Colors
CSI='\033['
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CEND="${CSI}0m"


##################################
# Process Interactive
##################################
if [ "$INTERACTIVE" = true ]; then
  echo -e "\nWhich Distro are you compiling Nginx for ?"
  echo -e "  [1] Debian"
  echo -e "  [2] Ubuntu\n"
  while [[ "$DISTRO_CHOICE" != "1" && "$DISTRO_CHOICE" != "2" ]]; do
    echo -ne "Select an option (1-2) [2]: " && read -r DISTRO_CHOICE
    case "${DISTRO_CHOICE}" in
      [1]* )
        ;;
      [2]* )
        ;;
      * )
        DISTRO_CHOICE="2"
        ;;
    esac
  done
  if [ "$DISTRO_CHOICE" = "1" ]; then
    echo -e "\nWhich version of Debian ?"
    echo -e "  [1] Debian 11 bullseye (11.1)"
    echo -e "  [2] Debian 10 buster (10.11)\n"
    while [[ "$DISTRO_VERSION" != "1" && "$DISTRO_VERSION" != "2" ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r DISTRO_VERSION
      case "${DISTRO_VERSION}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          DISTRO_VERSION="1"
          ;;
      esac
    done
  else
    echo -e "\nWhich version of Ubuntu ?"
    echo -e "  [1] Ubuntu 20.04 Focal Fossa"
    echo -e "  [2] Ubuntu 18.04 Bionic Beaver\n"
    while [[ "$DISTRO_VERSION" != "1" && "$DISTRO_VERSION" != "2" ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r DISTRO_VERSION
      case "${DISTRO_VERSION}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          DISTRO_VERSION="1"
          ;;
      esac
    done
  fi

  echo -e "\nWhich Nginx would you like to compile ?"
  echo -e "  [1] Mainline v${NGINX_MAINLINE}-${NGINX_MAINLINE_SUB}"
  echo -e "  [2] Stable v${NGINX_STABLE}-${NGINX_STABLE_SUB}\n"
  while [[ "$NGINX_RELEASE" != "1" && "$NGINX_RELEASE" != "2" ]]; do
    echo -ne "Select an option (1-2) [1]: " && read -r NGINX_RELEASE
    case "${NGINX_RELEASE}" in
      [1]* )
        ;;
      [2]* )
        ;;
      * )
        NGINX_RELEASE="1"
        ;;
    esac
  done

  echo -e "\nWhich SSL library do you prefer to compile Nginx with ?"
  echo -e "  [1] OpenSSL"
  echo -e "  [2] LibreSSL\n"
  while [[ "$SSL_LIB_CHOICE" != "1" && "$SSL_LIB_CHOICE" != "2" ]]; do
    echo -ne "Select an option (1-2) [1]: " && read -r SSL_LIB_CHOICE
    case "${SSL_LIB_CHOICE}" in
      [1]* )
        ;;
      [2]* )
        ;;
      * )
        SSL_LIB_CHOICE="1"
        ;;
    esac
  done
  if [ "$SSL_LIB_CHOICE" = "1" ]; then
    echo -e "\nWhat OpenSSL release do you want ?"
    echo -e "  [1] OpenSSL stable $OPENSSL_VER"
    echo -e "  [2] OpenSSL from system lib\n"
    while [[ "$OPENSSL_LIB" != "1" && "$OPENSSL_LIB" != "2" ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r OPENSSL_LIB
      case "${OPENSSL_LIB}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          OPENSSL_LIB="1"
          ;;
      esac
    done
  fi

  echo -e "\n\n\nNginx Modules Selection :"

  while [[ "$PAGESPEED" != "y" && "$PAGESPEED" != "n" ]]; do
    echo -ne "\nDo you want Pagespeed ? (Y/n) [Y]: " && read -r PAGESPEED
    case "${PAGESPEED}" in
      [Yy]* )
        PAGESPEED="y"
        ;;
      [Nn]* )
        PAGESPEED="n"
        ;;
      * )
        PAGESPEED="y"
        ;;
    esac
  done
  if [ "$PAGESPEED" = "y" ]; then
    echo -e "\nWhat Pagespeed release do you want ?"
    echo -e "  [1] Beta Release"
    echo -e "  [2] Stable Release\n"
    while [[ "$PAGESPEED_RELEASE" != "1" && "$PAGESPEED_RELEASE" != "2" ]]; do
      echo -ne "Select an option (1-2) [2]: " && read -r PAGESPEED_RELEASE
      case "${PAGESPEED_RELEASE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          PAGESPEED_RELEASE="2"
          ;;
      esac
    done
  fi

  while [[ "$BROTLI" != "y" && "$BROTLI" != "n" ]]; do
    echo -ne "\nDo you want Brotli ? (Y/n) [Y]: " && read -r BROTLI
    case "${BROTLI}" in
      [Yy]* )
        BROTLI="y"
        ;;
      [Nn]* )
        BROTLI="n"
        ;;
      * )
        BROTLI="y"
        ;;
    esac
  done

  while [[ "$HEADERS_MORE" != "y" && "$HEADERS_MORE" != "n" ]]; do
    echo -ne "\nDo you want Headers More ? (Y/n) [Y]: " && read -r HEADERS_MORE
    case "${HEADERS_MORE}" in
      [Yy]* )
        HEADERS_MORE="y"
        ;;
      [Nn]* )
        HEADERS_MORE="n"
        ;;
      * )
        HEADERS_MORE="y"
        ;;
    esac
  done

  while [[ "$CACHE_PURGE" != "y" && "$CACHE_PURGE" != "n" ]]; do
    echo -ne "\nDo you want Cache Purge ? (Y/n) [Y]: " && read -r CACHE_PURGE
    case "${CACHE_PURGE}" in
      [Yy]* )
        CACHE_PURGE="y"
        ;;
      [Nn]* )
        CACHE_PURGE="n"
        ;;
      * )
        CACHE_PURGE="y"
        ;;
    esac
  done

  while [[ "$VTS" != "y" && "$VTS" != "n" ]]; do
    echo -ne "\nDo you want Virtual Host Traffic Status ? (Y/n) [Y]: " && read -r VTS
    case "${VTS}" in
      [Yy]* )
        VTS="y"
        ;;
      [Nn]* )
        VTS="n"
        ;;
      * )
        VTS="y"
        ;;
    esac
  done

  while [[ "$GEOIP2" != "y" && "$GEOIP2" != "n" ]]; do
    echo -ne "\nDo you want GeoIP2 ? (Y/n) [Y]: " && read -r GEOIP2
    case "${GEOIP2}" in
      [Yy]* )
        GEOIP2="y"
        ;;
      [Nn]* )
        GEOIP2="n"
        ;;
      * )
        GEOIP2="y"
        ;;
    esac
  done

  while [[ "$ECHO" != "y" && "$ECHO" != "n" ]]; do
    echo -ne "\nDo you want Echo ? (Y/n) [Y]: " && read -r ECHO
    case "${ECHO}" in
      [Yy]* )
        ECHO="y"
        ;;
      [Nn]* )
        ECHO="n"
        ;;
      * )
        ECHO="y"
        ;;
    esac
  done

  while [[ "$MODSECURITY" != "y" && "$MODSECURITY" != "n" ]]; do
    echo -ne "\nDo you want ModSecurity ? (Y/n) [Y]: " && read -r MODSECURITY
    case "${MODSECURITY}" in
      [Yy]* )
        MODSECURITY="y"
        ;;
      [Nn]* )
        MODSECURITY="n"
        ;;
      * )
        MODSECURITY="y"
        ;;
    esac
  done

  while [[ "$NAXSI" != "y" && "$NAXSI" != "n" ]]; do
    echo -ne "\nDo you want NAXSI WAF (still experimental)? (Y/n) [Y]: " && read -r NAXSI
    case "${NAXSI}" in
      [Yy]* )
        NAXSI="y"
        ;;
      [Nn]* )
        NAXSI="n"
        ;;
      * )
        NAXSI="y"
        ;;
    esac
  done

  while [[ "$RTMP" != "y" && "$RTMP" != "n" ]]; do
    echo -ne "\nDo you want RTMP streaming module (used for video streaming) ? (y/N) [N] : " && read -r RTMP
    case "${RTMP}" in
      [Yy]* )
        RTMP="y"
        ;;
      [Nn]* )
        RTMP="n"
        ;;
      * )
        RTMP="n"
        ;;
    esac
  done
fi

if [ "$DISTRO_CHOICE" = "1" ]; then
  DISTRO_NAME="debian"
  if [ "$DISTRO_VERSION" = "1" ]; then
    DISTRO_CODENAME="bullseye"
    DISTRO_VERSION="11.1"
  else
    DISTRO_CODENAME="buster"
    DISTRO_VERSION="10.11"
  fi
else
  DISTRO_NAME="ubuntu"
  if [ "$DISTRO_VERSION" = "1" ]; then
    DISTRO_CODENAME="focal"
    DISTRO_VERSION="20.04"
  else
    DISTRO_CODENAME="bionic"
    DISTRO_VERSION="18.04"
  fi
fi

if [ "$NGINX_RELEASE" = "2" ]; then
  NGINX_VERSION="${NGINX_STABLE}"
  NGINX_SUBVERSION="${NGINX_STABLE_SUB}"
else
  NGINX_VERSION="${NGINX_MAINLINE}"
  NGINX_SUBVERSION="${NGINX_MAINLINE_SUB}"
fi

if [ "$SSL_LIB_CHOICE" = "1" ]; then
  LIBRESSL=false
  if [ "$OPENSSL_LIB" = "1" ]; then
    LATEST_OPENSSL=true
  else
    LATEST_OPENSSL=false
  fi
else
  LIBRESSL=true
  LATEST_OPENSSL=false
fi

if [ "$PAGESPEED" = "y" ]; then
  PAGESPEED=true
  if [ "$PAGESPEED_RELEASE" = "1" ]; then
    PAGESPEED_VERSION=v1.14.33.1-RC1
    PSOL_VERSION=1.13.35.2-x64
  else
    PAGESPEED_VERSION=v1.13.35.2-stable
    PSOL_VERSION=1.13.35.2-x64
  fi
else
  PAGESPEED=false
fi

if [ "$BROTLI" = "y" ]; then
  BROTLI=true
else
  BROTLI=false
fi

if [ "$HEADERS_MORE" = "y" ]; then
  HEADERS_MORE=true
else
  HEADERS_MORE=false
fi

if [ "$CACHE_PURGE" = "y" ]; then
  CACHE_PURGE=true
else
  CACHE_PURGE=false
fi

if [ "$VTS" = "y" ]; then
  VTS=true
else
  VTS=false
fi

if [ "$GEOIP2" = "y" ]; then
  GEOIP2=true
else
  GEOIP2=false
fi

if [ "$ECHO" = "y" ]; then
  ECHO=true
else
  ECHO=false
fi

if [ "$MODSECURITY" = "y" ]; then
  MODSECURITY=true
else
  MODSECURITY=false
fi

if [ "$NAXSI" = "y" ]; then
  NAXSI=true
else
  NAXSI=false
fi

if [ "$RTMP" = "y" ]; then
  RTMP=true
else
  RTMP=false
fi


# Load config for defaults and to build the final arrays used
if [ ! -f "./config" ]; then
  echo "config file not found."
  exit 1;
fi
source ./config

# clean previous install log
echo "" >$output_log

# Ensure http3 uses the right ssl
if [ "${BUILD_HTTP3}" = true ]; then
  for (( i = 0; i <= $package_counter; i++ ))
  do
    if [[ "${Sources[$i,Package]}" == "OpenSSL" || "${Sources[$i,Package]}" == "LibreSSL" ]]; then
      Sources[$i,Install]=false
    fi
    if [ "${Sources[$i,Package]}" == "BoringSSL" ]; then
      Sources[$i,Install]=true
    fi
  done
  required_packages="curl tar jq docker.io git mercurial rsync"
else
  required_packages="curl tar jq docker.io git"
fi

missing_packages=""
# check if required packages are installed
for package in $required_packages; do
  if ! package_installed "${package}"; then
    missing_packages="${missing_packages} ${package}"
  fi
done

# Checking if lsb_release is installed
if ! command_exists lsb_release; then
    missing_packages="${missing_packages} lsb-release"
fi

# Report any missing packages
if [ ! -z "${missing_packages}" ]; then
  echo "Please install the following package(s) :${missing_packages}"
  exit 0;
fi

# Module report
modules_static=""
modules_dynamic=""
modules_disabled=""
compile_pagespeed="No"
compile_naxsi="No"
compile_rtmp="No"
for (( i = 0; i <= $package_counter; i++ ))
do
  if [ "${Sources[$i,Install]}" = true ]; then
    if [ "${Sources[$i,ConfigureSwitch]}" == "--add-module" ]; then
      modules_static="${modules_static} ${Sources[$i,Package]},"
    fi
    if [ "${Sources[$i,ConfigureSwitch]}" == "--add-dynamic-module" ]; then
      modules_dynamic="${modules_dynamic} ${Sources[$i,Package]},"
    fi
  else
    if [[ "${Sources[$i,ConfigureSwitch]}" == "--add-module" || "${Sources[$i,ConfigureSwitch]}" == "--add-dynamic-module" ]]; then
      modules_disabled="${modules_disabled} ${Sources[$i,Package]},"
    fi
  fi
done
if [ -z "${modules_static}" ]; then
  modules_static=" None"
else
  modules_static="${modules_static::-1}"
fi
if [ -z "${modules_dynamic}" ]; then
  modules_dynamic=" None"
else
  modules_dynamic="${modules_dynamic::-1}"
fi
if [ -z "${modules_disabled}" ]; then
  modules_disabled=" None"
else
  modules_disabled="${modules_disabled::-1}"
fi


##################################
# Display Compilation Summary
##################################

echo ""
echo -e "${CGREEN}##################################${CEND}"
echo " Compilation summary "
echo -e "${CGREEN}##################################${CEND}"
echo ""
echo " Targeted OS   : ${DISTRO_NAME^} ${DISTRO_VERSION}"
echo " Detected Arch : ${OS_ARCH}"
echo " Logging in    : ${output_log}"
echo ""
echo -e "  - Nginx release : ${NGINX_VERSION}-${NGINX_SUBVERSION}"
if [ "${LATEST_OPENSSL}" = true ]; then
  echo -e "  - OpenSSL : ${OPENSSL_VERSION}"
else
  if [ "${LIBRESSL}" = true ]; then
    echo -e "  - LibreSSL : ${LIBRESSL_VERSION}"
  else
    echo -e "  - OpenSSL : Distro Default"
  fi
fi
if [ "$PAGESPEED" = true ]; then
  echo -e "  - Pagespeed : ${PAGESPEED_VERSION}"
fi
echo "  - Static modules :${modules_static}"
echo "  - Dynamic modules :${modules_dynamic}"
echo "  - Disabled modules :${modules_disabled}"
echo ""


exit 0;

##################################
# Fetch sources
##################################
echo -ne "       Downloading Modules                    "
if [ ! -d "src" ]; then
  mkdir src
fi
cd src

for (( i = 0; i <= $package_counter; i++ ))
do
  if [ "${Sources[$i,Install]}" = true ]; then
    if [ "${Sources[$i,Git]}" = true ]; then
      if [ ! -d "${Sources[$i,DLFinal]}" ]; then
        git clone --recursive "${Sources[$i,DLUrl]}" >>$output_log 2>&1
        if [ $? -ne 0 ]; then
          fail "Something went wrong while cloning git repo for ${Sources[$i,Package]}"
        fi
        if [ "${Sources[$i,DLFile]}" != "${Sources[$i,DLFinal]}" ]; then
          if [ -d "${Sources[$i,DLFile]}" ]; then
            mv "${Sources[$i,DLFile]}" "${Sources[$i,DLFinal]}"
          fi
        fi
        echo "${Sources[$i,Package]} cloned: OK" >>$output_log 2>&1
      else
        cd "${Sources[$i,DLFinal]}"
        git pull --recurse-submodules >>$output_log 2>&1
        if [ $? -ne 0 ]; then
          fail "Something went wrong while updating git repo for ${Sources[$i,Package]}"
        fi
        cd ..
        echo "${Sources[$i,Package]} up2date: OK" >>$output_log 2>&1
      fi
    else
      if [ ! -f "${Sources[$i,DLFinal]}" ]; then
        wget "${Sources[$i,DLUrl]}" >>$output_log 2>&1
        if [ $? -ne 0 ]; then
          if [ ! -z "${Sources[$i,DLAltUrl]}" ]; then
            wget "${Sources[$i,DLAltUrl]}" >>$output_log 2>&1
          else
            fail "Downloading ${Sources[$i,Package]} failed, no alternative url supplied."
          fi
        fi
      fi
      if [ "${Sources[$i,DLFile]}" != "${Sources[$i,DLFinal]}" ]; then
        if [ -f "${Sources[$i,DLFile]}" ]; then
          mv "${Sources[$i,DLFile]}" "${Sources[$i,DLFinal]}"
        fi
      fi
      if [ "${CHECKSUM_CHECKS}" = true ]; then
        echo "${Sources[$i,DLSha256]}" "${Sources[$i,DLFinal]}" | sha256sum --check
        if [ $? -ne 0 ]; then
          fail "Checksum for ${Sources[$i,DLFinal]} did NOT match, aborting with return code $?"
        fi
      else
        if [ ! -f "${Sources[$i,DLFinal]}" ]; then
          fail "${Sources[$i,DLFinal]} was not found."
        else
          echo "${Sources[$i,Package]} : Found." >>$output_log 2>&1
        fi
      fi
    fi
  fi
done
cd "${WORKPWD}"
echo -ne "[${CGREEN}OK${CEND}]\\r\n"
# exit 0;


##################################
# Setup build directory
##################################
echo -ne "       Setup Build folder                     "
if [ ! -d "build" ]; then
  mkdir build
else
  rm -Rf build
  mkdir build
fi
cd build

tar -zxf "${WORKPWD}/src/nginx_${NGINX_VERSION}.orig.tar.gz" >>$output_log 2>&1
cd "nginx-${NGINX_VERSION}"
tar -xf "${WORKPWD}/src/nginx_${NGINX_VERSION}-${NGINX_SUBVERSION}~${DISTRO_CODENAME}.debian.tar.xz" >>$output_log 2>&1
cd debian
mkdir modules
if [ "${BUILD_HTTP3}" = true ]; then
  cd "${WORKPWD}/src"
  if [ ! -d "nginx-quic" ]; then
    hg clone -b quic "${NGINX_QUIC_HG}" >>$output_log 2>&1
  else
    cd nginx-quic
    hg update >>$output_log 2>&1
    cd ..
  fi
  rsync -r "${WORKPWD}/src/nginx-quic/" "${WORKPWD}/build/nginx-${NGINX_VERSION}" >>$output_log 2>&1
fi

for (( i = 2; i <= $package_counter; i++ ))
do
  if [ "${Sources[$i,Install]}" = true ]; then
    cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/${Sources[$i,UnpackLoc]}"
    if [ "${Sources[$i,Git]}" = true ]; then
      cp -R "${WORKPWD}/src/${Sources[$i,DLFinal]}/" .
    else
      tar -zxf "${WORKPWD}/src/${Sources[$i,DLFinal]}" >>$output_log 2>&1
    fi
    if [ ! -z "${Sources[$i,ConfigureSwitch]}" ]; then
      cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian"
      if [ "${Sources[$i,Package]}" = "Naxsi" ]; then
        # Naxsi has a different folder structure then other modules...
        sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module ${Sources[$i,ConfigureSwitch]}=\"\$(CURDIR)\/debian\/modules\/${Sources[$i,UnpackName]}\/naxsi_src\"/g" rules >>$output_log 2>&1
      else
        sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module ${Sources[$i,ConfigureSwitch]}=\"\$(CURDIR)\/debian\/modules\/${Sources[$i,UnpackName]}\"/g" rules >>$output_log 2>&1
      fi
    fi
  fi
done
if [ "${BUILD_HTTP3}" = true ]; then
  cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian"
  sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --with-http_v3_module --with-http_quic_module --with-stream_quic_module/g" rules >>$output_log 2>&1
  sed -i "s/CFLAGS=\"\"/CFLAGS=\"-Wno-ignored-qualifiers\"/g" rules >>$output_log 2>&1
  sed -i "s/--with-cc-opt=\"\$(CFLAGS)\" --with-ld-opt=\"\$(LDFLAGS)\"/--with-cc-opt=\"-I..\/modules\/boringssl\/include \$(CFLAGS)\" --with-ld-opt=\"-L..\/modules\/boringssl\/build\/ssl -L..\/modules\/boringssl\/build\/crypto \$(LDFLAGS)\"/g" rules >>$output_log 2>&1
fi
echo -ne "[${CGREEN}OK${CEND}]\\r\n"


##################################
# Apply Patches
##################################
echo -ne "       Applying nginx patches                 "

cd "${WORKPWD}/build/nginx-${NGINX_VERSION}"
if [ "${LATEST_OPENSSL}" = true ]; then
  if [ "${OPENSSL_VERSION::1}" = "3" ]; then
    patch -p0 < "${WORKPWD}/custom/patches/openssl-3.0.x-compile.patch" >>$output_log 2>&1
  else
    patch -p0 < "${WORKPWD}/custom/patches/openssl-1.1.x-compile.patch" >>$output_log 2>&1
  fi
fi
if [ "${LIBRESSL}" = true ]; then
  patch -p0 < "${WORKPWD}/custom/patches/openssl-3.0.x-compile.patch" >>$output_log 2>&1
fi
if [ "${USE_CUSTOM_PATCHES}" = true ]; then
  if [ ! -f ".patchdone" ]; then
    cp "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6.patch" "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch"
    sed -i "s/@CACHEPVER@/${CACHE_PURGE_VERSION}/g" "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch" >>$output_log 2>&1
    patch -p0 < "${WORKPWD}/custom/patches/nginx-version.patch" >>$output_log 2>&1
    cd debian
    sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --with-http_v2_hpack_enc/g" rules >>$output_log 2>&1
    patch -p0 < "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch" >>$output_log 2>&1
    cd ..
    if [ "${BUILD_HTTP3}" = true ]; then
      patch -p1 < "${WORKPWD}/custom/patches/ngx_cloudflare_http2_hpack_1015003_http3.patch" >>$output_log 2>&1
    else
      patch -p1 < "${WORKPWD}/custom/patches/ngx_cloudflare_http2_hpack_1015003.patch" >>$output_log 2>&1
    fi
    patch -p1 < "${WORKPWD}/custom/patches/ngx_cloudflare_dynamic_tls_records_1015008.patch" >>$output_log 2>&1
    touch .patchdone
    rm -f "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch"
  fi
fi
echo -ne "[${CGREEN}OK${CEND}]\\r\n"


##################################
# Add Configs
##################################
echo -ne "       Adding custom configs                  "

cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian"
echo "/etc/nginx/sites-available" >> nginx.dirs
echo "/etc/nginx/sites-enabled" >> nginx.dirs
echo "/var/cache/nginx/pagespeed" >> nginx.dirs
if [ "${USE_CUSTOM_CONFIGS}" = true ]; then
  echo "/etc/nginx/conf.d/custom" >> nginx.dirs
  cp -f "${WORKPWD}/custom/configs/nginx.conf" "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/nginx.conf"
  mkdir custom
  cp -f ${WORKPWD}/custom/configs/*.conf* custom/
  for i in "${confs[@]}"
  do
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/$i \$\(INSTALLDIR\)\/etc\/nginx\/conf.d\/custom\/$i" rules >>$output_log 2>&1
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/$i \$\(INSTALLDIR\)\/etc\/nginx\/conf.d\/custom\/$i" nginx.rules.in >>$output_log 2>&1
  done
  sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/virtual.conf-example \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/virtual.conf-example" rules >>$output_log 2>&1
  sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/virtual.conf-example \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/virtual.conf-example" nginx.rules.in >>$output_log 2>&1
  if [ "${BUILD_HTTP3}" = true ]; then
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/virtual.conf-http3-example \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/virtual.conf-http3-example" rules >>$output_log 2>&1
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/virtual.conf-http3-example \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/virtual.conf-http3-example" nginx.rules.in >>$output_log 2>&1
  fi
  sed -i "s/^\tinstall -m 644 debian\/nginx.default.conf.*/\tinstall -m 644 debian\/custom\/nginx.default.conf \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/default.conf/g" rules >>$output_log 2>&1
  sed -i "s/^\tinstall -m 644 debian\/nginx.default.conf.*/\tinstall -m 644 debian\/custom\/nginx.default.conf \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/default.conf/g" nginx.rules.in >>$output_log 2>&1
  sed -i "/^\tln -s \/usr.*/i \\\tln -s \/etc\/nginx\/sites-available\/default.conf \$\(INSTALLDIR\)\/etc\/nginx\/sites-enabled\/default.conf" rules >>$output_log 2>&1
  sed -i "/^\tln -s \/usr.*/i \\\tln -s \/etc\/nginx\/sites-available\/default.conf \$\(INSTALLDIR\)\/etc\/nginx\/sites-enabled\/default.conf" nginx.rules.in >>$output_log 2>&1
fi
cd "${WORKPWD}"
echo -ne "[${CGREEN}OK${CEND}]\\r\n"
# exit 0;


##################################
# Build the package
##################################
if [ ! -d "output" ]; then
  mkdir output
else
  rm -Rf output
  mkdir output
fi

echo -ne "       Preparing Docker dev image             "
docker build -t "docker-deb-builder:${DISTRO_VERSION}" -f "docker/Dockerfile-${DISTRO_NAME}-${DISTRO_VERSION}" . >>$output_log 2>&1
if [ $? -ne 0 ]; then
  fail ""
else
  echo -ne "[${CGREEN}OK${CEND}]\\r\n"
fi
cd "${WORKPWD}"
export BUILD_HTTP3
echo -ne "       Compiling nginx                        "
./docker.sh -i "docker-deb-builder:${DISTRO_VERSION}" -o output "build/nginx-${NGINX_VERSION}" >>$output_log 2>&1
if [ $? -ne 0 ]; then
  fail ""
else
  echo -ne "[${CGREEN}OK${CEND}]\\r\n"
fi
echo -ne "       Testing result package                 "
./docker.sh -i "docker-deb-builder:${DISTRO_VERSION}" -o output -t "nginx-${NGINX_VERSION}" "build/nginx-${NGINX_VERSION}" >>$output_log 2>&1
if [ $? -ne 0 ]; then
  fail ""
else
  echo -ne "[${CGREEN}OK${CEND}]\\r\n"
fi

echo ""
echo -e "${CGREEN}##################################${CEND}"
echo " Result "
ls -l output/
echo -e "${CGREEN}##################################${CEND}"
echo ""
