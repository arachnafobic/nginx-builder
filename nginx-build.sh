#!/bin/bash

echo " ---------------------------------------------------------------------------- "
echo "   Nginx-builder : automated Nginx package creation with additional modules   "
echo " ---------------------------------------------------------------------------- "


##################################
# Initialize
##################################
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
while [[ $# -gt 0 ]]; do
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
CORANGE="${CSI}1;33m"
CGREEN="${CSI}1;32m"
CEND="${CSI}0m"


##################################
# Process Interactive
##################################
if [[ ${INTERACTIVE} = true ]]; then
  echo -e "\nWhich Distro are you compiling Nginx for ?"
  echo -e "  [1] Debian"
  echo -e "  [2] Ubuntu\n"
  while [[ ${DISTRO_CHOICE} != 1 && ${DISTRO_CHOICE} != 2 ]]; do
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
  if [[ ${DISTRO_CHOICE} = 1 ]]; then
    echo -e "\nWhich version of Debian ?"
    echo -e "  [1] Debian 11 bullseye (11.1)"
    echo -e "  [2] Debian 10 buster (10.11)\n"
    while [[ ${DISTRO_VERSION} != 1 && ${DISTRO_VERSION} != 2 ]]; do
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
    while [[ ${DISTRO_VERSION} != 1 && ${DISTRO_VERSION} != 2 ]]; do
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
  while [[ ${NGINX_RELEASE} != 1 && ${NGINX_RELEASE} != 2 ]]; do
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

  echo -e "\nDo you want to compile Nginx with HTTP/3 support ? (This will default SSL to BoringSSL)"
  echo -e "  [1] Without HTTP/3 support"
  echo -e "  [2] With HTTP/3 support\n"
  while [[ ${BUILD_HTTP3} != true && ${BUILD_HTTP3} != false ]]; do
    echo -ne "Select an option (1-2) [1]: " && read -r BUILD_HTTP3
    case "${BUILD_HTTP3}" in
      [1]* )
        BUILD_HTTP3=false
        ;;
      [2]* )
        BUILD_HTTP3=true
        ;;
      * )
        BUILD_HTTP3=false
        ;;
    esac
  done

  if [[ ${BUILD_HTTP3} = false ]]; then
    echo -e "\nWhich SSL library do you prefer to compile Nginx with ?"
    echo -e "  [1] OpenSSL"
    echo -e "  [2] LibreSSL\n"
    while [[ ${SSL_LIB_CHOICE} != 1 && ${SSL_LIB_CHOICE} != 2 ]]; do
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
    if [[ ${SSL_LIB_CHOICE} = 1 ]]; then
      echo -e "\nWhat OpenSSL release do you want ?"
      echo -e "  [1] OpenSSL stable $OPENSSL_VER"
      echo -e "  [2] OpenSSL from system lib\n"
      while [[ ${OPENSSL_LIB} != 1 && ${OPENSSL_LIB} != 2 ]]; do
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
  fi

  echo -e "\n\n\nNginx Modules Selection :"
  while [[ ${PAGESPEED} != y && ${PAGESPEED} != n ]]; do
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
  if [[ ${PAGESPEED} = y ]]; then
    echo -e "\nWhat Pagespeed release do you want ?"
    echo -e "  [1] Beta Release"
    echo -e "  [2] Stable Release\n"
    while [[ ${PAGESPEED_RELEASE} != 1 && ${PAGESPEED_RELEASE} != 2 ]]; do
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
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${PAGESPEED_COMPILE} != 1 && ${PAGESPEED_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r PAGESPEED_COMPILE
      case "${PAGESPEED_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          PAGESPEED_COMPILE="1"
          ;;
      esac
    done
  fi

  while [[ ${BROTLI} != true && ${BROTLI} != false ]]; do
    echo -ne "\nDo you want Brotli ? (Y/n) [Y]: " && read -r BROTLI
    case "${BROTLI}" in
      [Yy]* )
        BROTLI=true
        ;;
      [Nn]* )
        BROTLI=false
        ;;
      * )
        BROTLI=true
        ;;
    esac
  done
  if [[ ${BROTLI} = true ]]; then
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${BROTLI_COMPILE} != 1 && ${BROTLI_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r BROTLI_COMPILE
      case "${BROTLI_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          BROTLI_COMPILE="1"
          ;;
      esac
    done
  fi

  while [[ ${HEADERS_MORE} != true && ${HEADERS_MORE} != false ]]; do
    echo -ne "\nDo you want Headers More ? (Y/n) [Y]: " && read -r HEADERS_MORE
    case "${HEADERS_MORE}" in
      [Yy]* )
        HEADERS_MORE=true
        ;;
      [Nn]* )
        HEADERS_MORE=false
        ;;
      * )
        HEADERS_MORE=true
        ;;
    esac
  done
  if [[ ${HEADERS_MORE} = true ]]; then
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${HEADERS_MORE_COMPILE} != 1 && ${HEADERS_MORE_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r HEADERS_MORE_COMPILE
      case "${HEADERS_MORE_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          HEADERS_MORE_COMPILE="1"
          ;;
      esac
    done
  fi

  while [[ ${CACHE_PURGE} != true && ${CACHE_PURGE} != false ]]; do
    echo -ne "\nDo you want Cache Purge ? (Y/n) [Y]: " && read -r CACHE_PURGE
    case "${CACHE_PURGE}" in
      [Yy]* )
        CACHE_PURGE=true
        ;;
      [Nn]* )
        CACHE_PURGE=false
        ;;
      * )
        CACHE_PURGE=true
        ;;
    esac
  done
  if [[ ${CACHE_PURGE} = true ]]; then
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${CACHE_PURGE_COMPILE} != 1 && ${CACHE_PURGE_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r CACHE_PURGE_COMPILE
      case "${CACHE_PURGE_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          CACHE_PURGE_COMPILE="1"
          ;;
      esac
    done
  fi

  while [[ ${VTS} != true && ${VTS} != false ]]; do
    echo -ne "\nDo you want Virtual Host Traffic Status ? (Y/n) [Y]: " && read -r VTS
    case "${VTS}" in
      [Yy]* )
        VTS=true
        ;;
      [Nn]* )
        VTS=false
        ;;
      * )
        VTS=true
        ;;
    esac
  done
  if [[ ${VTS} = true ]]; then
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${VTS_COMPILE} != 1 && ${VTS_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r VTS_COMPILE
      case "${VTS_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          VTS_COMPILE="1"
          ;;
      esac
    done
  fi

  while [[ ${GEOIP2} != true && ${GEOIP2} != false ]]; do
    echo -ne "\nDo you want GeoIP2 ? (Y/n) [Y]: " && read -r GEOIP2
    case "${GEOIP2}" in
      [Yy]* )
        GEOIP2=true
        ;;
      [Nn]* )
        GEOIP2=false
        ;;
      * )
        GEOIP2=true
        ;;
    esac
  done
  if [[ ${GEOIP2} = true ]]; then
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${GEOIP2_COMPILE} != 1 && ${GEOIP2_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r GEOIP2_COMPILE
      case "${GEOIP2_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          GEOIP2_COMPILE="1"
          ;;
      esac
    done
  fi

  while [[ ${ECHO} != true && ${ECHO} != false ]]; do
    echo -ne "\nDo you want Echo ? (Y/n) [Y]: " && read -r ECHO
    case "${ECHO}" in
      [Yy]* )
        ECHO=true
        ;;
      [Nn]* )
        ECHO=false
        ;;
      * )
        ECHO=true
        ;;
    esac
  done
  if [[ ${ECHO} = true ]]; then
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${ECHO_COMPILE} != 1 && ${ECHO_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r ECHO_COMPILE
      case "${ECHO_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          ECHO_COMPILE="1"
          ;;
      esac
    done
  fi

  while [[ ${MODSECURITY} != true && ${MODSECURITY} != false ]]; do
    echo -ne "\nDo you want ModSecurity ? (Y/n) [Y]: " && read -r MODSECURITY
    case "${MODSECURITY}" in
      [Yy]* )
        MODSECURITY=true
        ;;
      [Nn]* )
        MODSECURITY=false
        ;;
      * )
        MODSECURITY=true
        ;;
    esac
  done
  if [[ ${MODSECURITY} = true ]]; then
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${MODSECURITY_COMPILE} != 1 && ${MODSECURITY_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r MODSECURITY_COMPILE
      case "${MODSECURITY_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          MODSECURITY_COMPILE="1"
          ;;
      esac
    done
  fi

  while [[ ${NAXSI} != true && ${NAXSI} != false ]]; do
    echo -ne "\nDo you want NAXSI WAF (still experimental)? (Y/n) [Y]: " && read -r NAXSI
    case "${NAXSI}" in
      [Yy]* )
        NAXSI=true
        ;;
      [Nn]* )
        NAXSI=false
        ;;
      * )
        NAXSI=true
        ;;
    esac
  done
  if [[ ${NAXSI} = true ]]; then
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${NAXSI_COMPILE} != 1 && ${NAXSI_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r NAXSI_COMPILE
      case "${NAXSI_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          NAXSI_COMPILE="1"
          ;;
      esac
    done
  fi

  while [[ ${RTMP} != true && ${RTMP} != false ]]; do
    echo -ne "\nDo you want RTMP streaming module (used for video streaming) ? (y/N) [N] : " && read -r RTMP
    case "${RTMP}" in
      [Yy]* )
        RTMP=true
        ;;
      [Nn]* )
        RTMP=false
        ;;
      * )
        RTMP=false
        ;;
    esac
  done
  if [[ ${RTMP} = true ]]; then
    echo -e "\nCompile as Static or Dynamic module ?"
    echo -e "  [1] Static"
    echo -e "  [2] Dynamic\n"
    while [[ ${RTMP_COMPILE} != 1 && ${RTMP_COMPILE} != 2 ]]; do
      echo -ne "Select an option (1-2) [1]: " && read -r RTMP_COMPILE
      case "${RTMP_COMPILE}" in
        [1]* )
          ;;
        [2]* )
          ;;
        * )
          RTMP_COMPILE="1"
          ;;
      esac
    done
  fi

  echo -e "\n\n\nExtra's :"
  while [[ ${USE_CUSTOM_PATCHES} != true && ${USE_CUSTOM_PATCHES} != false ]]; do
    echo -ne "\nDo you want the nginx patches to be applied ? (Y/n) [Y] : " && read -r USE_CUSTOM_PATCHES
    case "${USE_CUSTOM_PATCHES}" in
      [Yy]* )
        USE_CUSTOM_PATCHES=true
        ;;
      [Nn]* )
        USE_CUSTOM_PATCHES=false
        ;;
      * )
        USE_CUSTOM_PATCHES=true
        ;;
    esac
  done

  while [[ ${USE_CUSTOM_CONFIGS} != true && ${USE_CUSTOM_CONFIGS} != false ]]; do
    echo -ne "\nDo you want the custom configs added to /etc/nginx ? (Y/n) [Y] : " && read -r USE_CUSTOM_CONFIGS
    case "${USE_CUSTOM_CONFIGS}" in
      [Yy]* )
        USE_CUSTOM_CONFIGS=true
        ;;
      [Nn]* )
        USE_CUSTOM_CONFIGS=false
        ;;
      * )
        USE_CUSTOM_CONFIGS=true
        ;;
    esac
  done
fi

if [[ ${NGINX_RELEASE} = 2 ]]; then
  NGINX_VERSION="${NGINX_STABLE}"
  NGINX_SUBVERSION="${NGINX_STABLE_SUB}"
else
  NGINX_VERSION="${NGINX_MAINLINE}"
  NGINX_SUBVERSION="${NGINX_MAINLINE_SUB}"
fi

if [[ ${SSL_LIB_CHOICE} = 1 ]]; then
  LIBRESSL=false
  if [[ ${OPENSSL_LIB} = 1 ]]; then
    LATEST_OPENSSL=true
  else
    LATEST_OPENSSL=false
  fi
else
  LIBRESSL=true
  LATEST_OPENSSL=false
fi


# Load config for defaults and to build the final arrays used
if [[ ! -f ./config ]]; then
  echo "config file not found."
  exit 1;
fi
source ./config

if [[ ${LATEST_OPENSSL} = true && ${LIBRESSL} = true ]]; then
  echo "Both Latest OpenSSL and LibreSSL are set to true in the config, this is not possible to run."
  exit 1;
fi

if [[ ${NGINX_VERSION:2:2} == "21" ]]; then
  if [[ ${NGINX_VERSION:5} > 4 ]]; then
    if [[ ${NAXSI} = true || ${MODSECURITY} = true ]]; then
      if [[ ${NAXSI_VERSION} < "1.4" || ${MODSECURITY_VERSION} < "1.0.3" ]]; then
        echo "You have selected an nginx release higher then 1.21.4, this version is incompatible with naxsi <1.3 and modsecurity <1.0.2"
        echo "Please adjust in the config and retry"
        exit 1;
      fi
    fi
  fi
fi

# clean previous install log
echo "" >$output_log

# Pagespeed Psol has different urls for versions passed 1.14.x
if [[ ${PAGESPEED} = true ]]; then
  for (( i = 0; i <= $package_counter; i++ ))
  do
    if [[ ${Sources[$i,Package]} = "Pagespeed Psol" ]]; then
      if [[ ${PAGESPEED_RELEASE} = 1 ]]; then
        Sources[$i,DLFile]="psol-${PSOL_VERSION}-apache-incubating-x64.tar.gz"
        Sources[$i,DLUrl]="https://dist.apache.org/repos/dist/release/incubator/pagespeed/${PSOL_VERSION}/x64/psol-${PSOL_VERSION}-apache-incubating-x64.tar.gz"
        Sources[$i,DLFinal]="psol-${PSOL_VERSION}-apache-incubating-x64.tar.gz"
      else
        Sources[$i,DLFile]="${PSOL_VERSION}.tar.gz"
        Sources[$i,DLUrl]="https://dl.google.com/dl/page-speed/psol/${PSOL_VERSION}.tar.gz"
        Sources[$i,DLFinal]="psol-${PSOL_VERSION}.tar.gz"
      fi
    fi
  done
fi

# Ensure http3 uses the right ssl
if [[ ${BUILD_HTTP3} = true ]]; then
  for (( i = 0; i <= $package_counter; i++ ))
  do
    if [[ ${Sources[$i,Package]} = OpenSSL || ${Sources[$i,Package]} = LibreSSL ]]; then
      Sources[$i,Install]=false
    fi
    if [[ ${Sources[$i,Package]} = BoringSSL ]]; then
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
if [[ ! -z ${missing_packages} ]]; then
  echo "Please install the following package(s) :${missing_packages}"
  exit 1;
fi

# Module report
modules_static=""
modules_dynamic=""
modules_disabled=""
SETUP_DYNAMIC=false
for (( i = 0; i <= $package_counter; i++ ))
do
  if [[ ${Sources[$i,Install]} = true ]]; then
    if [[ ${Sources[$i,ConfigureSwitch]} = --add-module ]]; then
      modules_static="${modules_static} ${Sources[$i,Package]},"
    fi
    if [[ ${Sources[$i,ConfigureSwitch]} = --add-dynamic-module ]]; then
      modules_dynamic="${modules_dynamic} ${Sources[$i,Package]},"
    fi
  else
    if [[ ${Sources[$i,ConfigureSwitch]} = --add-module || ${Sources[$i,ConfigureSwitch]} = --add-dynamic-module ]]; then
      modules_disabled="${modules_disabled} ${Sources[$i,Package]},"
    fi
  fi
done
if [[ -z ${modules_static} ]]; then
  modules_static=" None"
else
  modules_static="${modules_static::-1}"
fi
if [[ -z ${modules_dynamic} ]]; then
  modules_dynamic=" None"
else
  modules_dynamic="${modules_dynamic::-1}"
  SETUP_DYNAMIC=true
fi
if [[ -z ${modules_disabled} ]]; then
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
if [[ ${BUILD_HTTP3} = true ]]; then
  echo -e "  - SSL : BoringSSL (HTTP/3)"
else
  if [[ ${LATEST_OPENSSL} = true ]]; then
    echo -e "  - OpenSSL : ${OPENSSL_VERSION}"
  else
    if [[ ${LIBRESSL} = true ]]; then
      echo -e "  - LibreSSL : ${LIBRESSL_VERSION}"
    else
      echo -e "  - OpenSSL : Distro Default"
    fi
  fi
fi
if [[ ${PAGESPEED} = true ]]; then
  echo -e "  - Pagespeed : ${PAGESPEED_VERSION}"
fi
echo "  - Static modules :${modules_static}"
echo "  - Dynamic modules :${modules_dynamic}"
echo "  - Disabled modules :${modules_disabled}"
echo ""
if [[ ${USE_CUSTOM_PATCHES} = true ]]; then
  echo "  - Apply Patches : Yes"
else
  echo "  - Apply Patches : No"
fi
if [[ ${USE_CUSTOM_CONFIGS} = true ]]; then
  echo "  - Add custom configs : Yes"
else
  echo "  - Add custom configs : No"
fi
echo -e "\n${CGREEN}##################################${CEND}\n"
# exit 0;


##################################
# Fetch sources
##################################
echo -ne "       Downloading Modules                    "
if [[ ! -d src ]]; then
  mkdir src
fi
cd src

for (( i = 0; i <= $package_counter; i++ ))
do
  if [[ ${Sources[$i,Install]} = true ]]; then
    if [[ ${Sources[$i,Git]} = true ]]; then
      if [[ ! -d ${Sources[$i,DLFinal]} ]]; then
        git clone --recursive "${Sources[$i,DLUrl]}" >>$output_log 2>&1
        if [[ $? -ne 0 ]]; then
          fail "Something went wrong while cloning git repo for ${Sources[$i,Package]}"
        fi
        if [[ ${Sources[$i,DLFile]} != ${Sources[$i,DLFinal]} ]]; then
          if [[ -d ${Sources[$i,DLFile]} ]]; then
            mv "${Sources[$i,DLFile]}" "${Sources[$i,DLFinal]}"
          fi
        fi
        echo "${Sources[$i,Package]} cloned: OK" >>$output_log 2>&1
      else
        cd "${Sources[$i,DLFinal]}"
        git pull --recurse-submodules >>$output_log 2>&1
        if [[ $? -ne 0 ]]; then
          fail "Something went wrong while updating git repo for ${Sources[$i,Package]}"
        fi
        cd ..
        echo "${Sources[$i,Package]} up2date: OK" >>$output_log 2>&1
      fi
    else
      if [[ ! -f ${Sources[$i,DLFinal]} ]]; then
        wget "${Sources[$i,DLUrl]}" >>$output_log 2>&1
        if [[ $? -ne 0 ]]; then
          if [[ ! -z ${Sources[$i,DLAltUrl]} ]]; then
            wget "${Sources[$i,DLAltUrl]}" >>$output_log 2>&1
          else
            fail "Downloading ${Sources[$i,Package]} failed, no alternative url supplied."
          fi
        fi
      fi
      if [[ ${Sources[$i,DLFile]} != ${Sources[$i,DLFinal]} ]]; then
        if [[ -f ${Sources[$i,DLFile]} ]]; then
          mv "${Sources[$i,DLFile]}" "${Sources[$i,DLFinal]}"
        fi
      fi
      if [[ ! -f ${Sources[$i,DLFinal]} ]]; then
        fail "${Sources[$i,DLFinal]} was not found."
      else
        echo "${Sources[$i,Package]} : Found." >>$output_log 2>&1
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
if [[ ! -d build ]]; then
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
if [[ ${BUILD_HTTP3} = true ]]; then
  cd "${WORKPWD}/src"
  if [[ ! -d nginx-quic ]]; then
    hg clone -b quic "${NGINX_QUIC_HG}" >>$output_log 2>&1
  else
    cd nginx-quic
    hg update >>$output_log 2>&1
    cd ..
  fi
  rsync -r "${WORKPWD}/src/nginx-quic/" "${WORKPWD}/build/nginx-${NGINX_VERSION}" >>$output_log 2>&1
fi

if [[ ${SETUP_DYNAMIC} = true ]]; then
  cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/modules"
  wget https://hg.nginx.org/pkg-oss/raw-file/default/build_module.sh >>$output_log 2>&1
  chmod a+x build_module.sh
  touch build_modules.sh
  chmod a+x build_modules.sh
fi

for (( i = 2; i <= $package_counter; i++ ))
do
  if [[ ${Sources[$i,Install]} = true ]]; then
    cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/${Sources[$i,UnpackLoc]}"
    if [[ ${Sources[$i,Git]} = true ]]; then
      cp -R "${WORKPWD}/src/${Sources[$i,DLFinal]}/" .
    else
      tar -zxf "${WORKPWD}/src/${Sources[$i,DLFinal]}" >>$output_log 2>&1
    fi
    if [[ ! -z ${Sources[$i,ConfigureSwitch]} ]]; then
      cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian"
      if [[ ${Sources[$i,Package]} = Naxsi ]]; then
        # Naxsi has a different folder structure then other modules...
        sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module ${Sources[$i,ConfigureSwitch]}=\"\$(CURDIR)\/debian\/modules\/${Sources[$i,UnpackName]}\/naxsi_src\"/g" rules >>$output_log 2>&1
        if [[ ${Sources[$i,ConfigureSwitch]} = --add-dynamic-module ]]; then
          echo "./build_module.sh -y -v ${NGINX_VERSION} -o /output/ -n ${Sources[$i,Nickname]} ${Sources[$i,UnpackName]}/naxsi_src/" >> modules/build_modules.sh
        fi
      else
        sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module ${Sources[$i,ConfigureSwitch]}=\"\$(CURDIR)\/debian\/modules\/${Sources[$i,UnpackName]}\"/g" rules >>$output_log 2>&1
        if [[ ${Sources[$i,ConfigureSwitch]} = --add-dynamic-module ]]; then
          if [[ ${Sources[$i,Package]} = Pagespeed ]]; then
            echo "echo y|./build_module.sh -y -v ${NGINX_VERSION} -o /output/ -n ${Sources[$i,Nickname]} ${Sources[$i,UnpackName]}/." >> modules/build_modules.sh
          elif [[ ${Sources[$i,Package]} = Brotli || ${Sources[$i,Package]} = "Cache Purge" ]]; then
            echo "./build_module.sh -y -f -v ${NGINX_VERSION} -o /output/ -n ${Sources[$i,Nickname]} ${Sources[$i,UnpackName]}/." >> modules/build_modules.sh
          else
            echo "./build_module.sh -y -v ${NGINX_VERSION} -o /output/ -n ${Sources[$i,Nickname]} ${Sources[$i,UnpackName]}/." >> modules/build_modules.sh
          fi
        fi
      fi
    fi
  fi
done
if [[ ${LATEST_OPENSSL} = true ]]; then
  if [[ ${OPENSSL_VERSION::1} = 3 ]]; then
#    DEB_CFLAGS='-m64 -march=native -mtune=native -DTCP_FASTOPEN=23 -g -O3 -fstack-protector-strong -flto -ffat-lto-objects -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wimplicit-fallthrough=0 -fcode-hoisting -Wp,-D_FORTIFY_SOURCE=2 -gsplit-dwarf'
#    DEB_LFLAGS='-lrt -ljemalloc -Wl,-z,relro -Wl,-z,now -fPIC -flto -ffat-lto-objects'
    DEB_CFLAGS='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC -Wno-error'
    DEB_LDFLAGS='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie -Wno-error'

    sed -i "s/CFLAGS=\"\"/CFLAGS=\"${DEB_CFLAGS}\" LDFLAGS=\"${DEB_LDFLAGS}\"/g" rules >>$output_log 2>&1
  fi
fi
if [[ ${BUILD_HTTP3} = true ]]; then
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
if [[ ${LATEST_OPENSSL} = true ]]; then
  if [[ ${OPENSSL_VERSION::1} = 3 ]]; then
    patch -p0 < "${WORKPWD}/custom/patches/openssl-3.0.x-compile.patch" >>$output_log 2>&1
  else
    patch -p0 < "${WORKPWD}/custom/patches/openssl-1.1.x-compile.patch" >>$output_log 2>&1
  fi
fi
if [[ ${LIBRESSL} = true ]]; then
  patch -p0 < "${WORKPWD}/custom/patches/openssl-3.0.x-compile.patch" >>$output_log 2>&1
fi
if [[ ${USE_CUSTOM_PATCHES} = true ]]; then
  if [[ ! -f .patchdone ]]; then
    cp "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6.patch" "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch"
    sed -i "s/@CACHEPVER@/${CACHE_PURGE_VERSION}/g" "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch" >>$output_log 2>&1
    patch -p0 < "${WORKPWD}/custom/patches/nginx-version.patch" >>$output_log 2>&1
    cd debian
    sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --with-http_v2_hpack_enc/g" rules >>$output_log 2>&1
    patch -p0 < "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch" >>$output_log 2>&1
    cd ..
    if [[ ${BUILD_HTTP3} = true ]]; then
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
if [[ ${SETUP_DYNAMIC} = true ]]; then
  echo "/usr/share/nginx/modules" >> nginx.dirs
  for (( i = 2; i <= $package_counter; i++ ))
  do
    if [[ ${Sources[$i,ConfigureSwitch]} = --add-dynamic-module ]]; then
      sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/module-${Sources[$i,Nickname]}.conf \$\(INSTALLDIR\)\/usr\/share\/nginx\/modules\/module-${Sources[$i,Nickname]}.conf" rules >>$output_log 2>&1
      sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/module-${Sources[$i,Nickname]}.conf \$\(INSTALLDIR\)\/usr\/share\/nginx\/modules\/module-${Sources[$i,Nickname]}.conf" nginx.rules.in >>$output_log 2>&1
    fi
  done
fi
mkdir custom
cp -f ${WORKPWD}/custom/configs/*.conf* custom/
if [[ ${USE_CUSTOM_CONFIGS} = true ]]; then
  echo "/etc/nginx/conf.d/custom" >> nginx.dirs
  cp -f "${WORKPWD}/custom/configs/nginx.conf" "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/nginx.conf"
  for i in "${confs[@]}"
  do
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/$i \$\(INSTALLDIR\)\/etc\/nginx\/conf.d\/custom\/$i" rules >>$output_log 2>&1
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/$i \$\(INSTALLDIR\)\/etc\/nginx\/conf.d\/custom\/$i" nginx.rules.in >>$output_log 2>&1
  done
  sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/virtual.conf-example \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/virtual.conf-example" rules >>$output_log 2>&1
  sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/virtual.conf-example \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/virtual.conf-example" nginx.rules.in >>$output_log 2>&1
  if [[ ${BUILD_HTTP3} = true ]]; then
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
if [[ ! -d output ]]; then
  mkdir output
else
  rm -Rf output
  mkdir output
fi

echo -ne "       Preparing Docker dev image             "
docker build -t "docker-deb-builder:${DISTRO_VERSION}" -f "docker/Dockerfile-${DISTRO_NAME}-${DISTRO_VERSION}" . >>$output_log 2>&1
if [[ $? -ne 0 ]]; then
  fail ""
else
  echo -ne "[${CGREEN}OK${CEND}]\\r\n"
fi
cd "${WORKPWD}"
export BUILD_HTTP3
export SETUP_DYNAMIC
echo -ne "       Compiling nginx                        "
./docker.sh -i "docker-deb-builder:${DISTRO_VERSION}" -o output "build/nginx-${NGINX_VERSION}" >>$output_log 2>&1
if [[ $? -ne 0 ]]; then
  fail ""
else
  echo -ne "[${CGREEN}OK${CEND}]\\r\n"
fi
echo -ne "       Testing result package                 "
./docker.sh -i "docker-deb-builder:${DISTRO_VERSION}" -o output -t "nginx-${NGINX_VERSION}" "build/nginx-${NGINX_VERSION}" >>$output_log 2>&1
if [[ $? -ne 0 ]]; then
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
