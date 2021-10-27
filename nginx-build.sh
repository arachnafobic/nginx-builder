#!/bin/bash

##################################
# Initialize
##################################
if [ ! -f "./config" ]; then
  echo "config file not found."
  exit 1;
fi
source ./config

if [ "${BUILD_HTTP3}" = true ]; then
  Sources[2,Install]=false
  Sources[12,Install]=true
  required_packages="curl tar jq docker.io git mercurial rsync"
else
  required_packages="curl tar jq docker.io git"
fi

# check if a command exist
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

##################################
# Variables
##################################
WORKPWD="${PWD}"
readonly OS_ARCH="$(uname -m)"

# Colors
CSI='\033['
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CEND="${CSI}0m"

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
    if [ "${Sources[$i,Package]}" == "Pagespeed" ]; then
      compile_pagespeed="Yes"
    fi
    if [ "${Sources[$i,Package]}" == "Naxsi" ]; then
      compile_naxsi="Yes"
    fi
    if [ "${Sources[$i,Package]}" == "RTMP" ]; then
      compile_rtmp="Yes"
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
  modules_disabled="${modules_dynamic::-1}"
fi

# clean previous install log
echo "" >$output_log

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
  echo -e "  - OPENSSL : ${OPENSSL_VERSION}"
else
  echo -e "  - OPENSSL : Distro Default"
fi
echo "  - Static modules :${modules_static}"
echo "  - Dynamic modules :${modules_dynamic}"
echo "  - Disabled modules :${modules_dynamic}"
echo "  - Pagespeed : ${compile_pagespeed}"
echo "  - Naxsi : ${compile_naxsi}"
echo "  - RTMP : ${compile_rtmp}"
#  -n "$LIBRESSL_VALID"
#    echo -e "  - LIBRESSL : $LIBRESSL_VALID"
echo ""

# Fetch sources
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


# Setup build directory
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
echo -ne "       Applying nginx patches                 "

cd "${WORKPWD}/build/nginx-${NGINX_VERSION}"
if [ "${LATEST_OPENSSL}" = true ]; then
  if [ "${OPENSSL_VERSION::1}" = "3" ]; then
    patch -p0 < "${WORKPWD}/custom/patches/openssl-3.0.x-compile.patch" >>$output_log 2>&1
  else
    patch -p0 < "${WORKPWD}/custom/patches/openssl-1.1.x-compile.patch" >>$output_log 2>&1
  fi
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


# Build the package
if [ ! -d "output" ]; then
  mkdir output
else
  rm -Rf output
  mkdir output
fi

echo -ne "       Preparing Docker dev image             "
docker build -t "docker-deb-builder:${DISTRO_VERSION}" -f "docker/Dockerfile-${DISTRO_NAME}-${DISTRO_VERSION}" . >>$output_log 2>&1
echo -ne "[${CGREEN}OK${CEND}]\\r\n"
cd "${WORKPWD}"
export BUILD_HTTP3
echo -ne "       Compiling nginx                        "
./docker.sh -i "docker-deb-builder:${DISTRO_VERSION}" -o output "build/nginx-${NGINX_VERSION}" >>$output_log 2>&1
echo -ne "[${CGREEN}OK${CEND}]\\r\n"
echo -ne "       Testing result package                 "
./docker.sh -i "docker-deb-builder:${DISTRO_VERSION}" -o output -t "nginx-${NGINX_VERSION}" "build/nginx-${NGINX_VERSION}" >>$output_log 2>&1
echo -ne "[${CGREEN}OK${CEND}]\\r\n"

echo ""
echo -e "${CGREEN}##################################${CEND}"
echo " Result "
ls -l output/
echo -e "${CGREEN}##################################${CEND}"
echo ""
