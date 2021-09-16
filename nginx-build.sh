#!/bin/bash

# Initialize
WORKPWD="${PWD}"
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

for i in {0..11}; do
  if [ "${Sources[$i,Install]}" = true ]; then
    if [ "${Sources[$i,Git]}" = true ]; then
      if [ ! -d "${Sources[$i,DLFinal]}" ]; then
        git clone --recursive "${Sources[$i,DLUrl]}"
        if [ $? -ne 0 ]; then
          echo "Something went wrong while cloning git repo for ${Sources[$i,Package]}"
          exit 1;
        fi
        if [ "${Sources[$i,DLFile]}" != "${Sources[$i,DLFinal]}" ]; then
          if [ -d "${Sources[$i,DLFile]}" ]; then
            mv "${Sources[$i,DLFile]}" "${Sources[$i,DLFinal]}"
          fi
        fi
        echo "${Sources[$i,Package]} cloned: OK"
      else
        cd "${Sources[$i,DLFinal]}"
        git pull --recurse-submodules
        if [ $? -ne 0 ]; then
          echo "Something went wrong while updating git repo for ${Sources[$i,Package]}"
          exit 1;
        fi
        cd ..
        echo "${Sources[$i,Package]} up2date: OK"
      fi
    else
      if [ ! -f "${Sources[$i,DLFinal]}" ]; then
        wget "${Sources[$i,DLUrl]}"
        if [ $? -ne 0 ]; then
          if [ ! -z "${Sources[$i,DLAltUrl]}" ]; then
            wget "${Sources[$i,DLAltUrl]}"
          else
            echo "Downloading ${Sources[$i,Install]} failed, no alternative url supplied."
          fi
        fi
      fi
      if [ "${Sources[$i,DLFile]}" != "${Sources[$i,DLFinal]}" ]; then
        if [ -f "${Sources[$i,DLFile]}" ]; then
          mv "${Sources[$i,DLFile]}" "${Sources[$i,DLFinal]}"
        fi
      fi
      echo -ne "${Sources[$i,Package]} : "
      if [ "${CHECKSUM_CHECKS}" = true ]; then
        echo "${Sources[$i,DLSha256]}" "${Sources[$i,DLFinal]}" | sha256sum --check
        if [ $? -ne 0 ]; then
          echo "Checksum for ${Sources[$i,DLFinal]} did NOT match, aborting with return code $?"
          exit 1;
        fi
      else
        if [ ! -f "${Sources[$i,DLFinal]}" ]; then
          echo "Not Found."
          exit 1;
        else
          echo "Found."
        fi
      fi
    fi
  fi
done
cd "${WORKPWD}"
# exit 0;


# Setup build directory
if [ ! -d "build" ]; then
  mkdir build
else
  rm -Rf build
  mkdir build
fi
cd build

tar -zxf "${WORKPWD}/src/nginx_${NGINX_VERSION}.orig.tar.gz"
cd "nginx-${NGINX_VERSION}"
tar -xf "${WORKPWD}/src/nginx_${NGINX_VERSION}-1~${DISTRO_NAME}.debian.tar.xz"
cd debian
mkdir modules

for i in {2..11}; do
  if [ "${Sources[$i,Install]}" = true ]; then
    cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/${Sources[$i,UnpackLoc]}"
    if [ "${Sources[$i,Git]}" = true ]; then
      cp -R "${WORKPWD}/src/${Sources[$i,DLFinal]}/" .
    else
      tar -zxf "${WORKPWD}/src/${Sources[$i,DLFinal]}"
    fi
    if [ ! -z "${Sources[$i,ConfigureSwitch]}" ]; then
      cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian"
      sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module ${Sources[$i,ConfigureSwitch]}=\"\$(CURDIR)\/debian\/modules\/${Sources[$i,UnpackName]}\"/g" rules
    fi

  fi
done

cd "${WORKPWD}/build/nginx-${NGINX_VERSION}"
if [ "${LATEST_OPENSSL}" = true ]; then
  patch -p0 < "${WORKPWD}/custom/patches/openssl-compile.patch"
fi
if [ "${USE_CUSTOM_PATCHES}" = true ]; then
  if [ ! -f ".patchdone" ]; then
    cp "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6.patch" "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch"
    sed -i "s/@CACHEPVER@/${CACHE_PURGE_VERSION}/g" "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch"
    patch -p0 < "${WORKPWD}/custom/patches/nginx-version.patch"
    cd debian
    sed -i "s/--with-mail_ssl_module/--with-mail_ssl_module --with-http_v2_hpack_enc/g" rules
    patch -p0 < "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch"
    cd ..
    patch -p1 < "${WORKPWD}/custom/patches/ngx_cloudflare_http2_hpack_1015003.patch"
    patch -p1 < "${WORKPWD}/custom/patches/ngx_cloudflare_dynamic_tls_records_1015008.patch"
    touch .patchdone
    rm -f "${WORKPWD}/custom/patches/ngx_cache_purge-fix-compatibility-with-nginx-1.11.6_sed.patch"
  fi
fi
cd "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian"
echo "/etc/nginx/sites-available" >> nginx.dirs
echo "/etc/nginx/sites-enabled" >> nginx.dirs
echo "/var/cache/nginx/pagespeed" >> nginx.dirs
if [ "${USE_CUSTOM_CONFIGS}" = true ]; then
  echo -en "Inserting Configs..."
  echo "/etc/nginx/conf.d/custom" >> nginx.dirs
  cp -f "${WORKPWD}/custom/configs/nginx.conf" "${WORKPWD}/build/nginx-${NGINX_VERSION}/debian/nginx.conf"
  mkdir custom
  cp -f ${WORKPWD}/custom/configs/*.conf* custom/
  for i in "${confs[@]}"
  do
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/$i \$\(INSTALLDIR\)\/etc\/nginx\/conf.d\/custom\/$i" rules
    sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/$i \$\(INSTALLDIR\)\/etc\/nginx\/conf.d\/custom\/$i" nginx.rules.in
  done
  sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/virtual.conf-example \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/virtual.conf-example" rules
  sed -i "/^\tln -s \/usr.*/a \\\tinstall -m 644 debian\/custom\/virtual.conf-example \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/virtual.conf-example" nginx.rules.in

  sed -i "s/^\tinstall -m 644 debian\/nginx.default.conf.*/\tinstall -m 644 debian\/custom\/nginx.default.conf \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/default.conf/g" rules
  sed -i "s/^\tinstall -m 644 debian\/nginx.default.conf.*/\tinstall -m 644 debian\/custom\/nginx.default.conf \$\(INSTALLDIR\)\/etc\/nginx\/sites-available\/default.conf/g" nginx.rules.in
  sed -i "/^\tln -s \/usr.*/i \\\tln -s \/etc\/nginx\/sites-available\/default.conf \$\(INSTALLDIR\)\/etc\/nginx\/sites-enabled\/default.conf" rules
  sed -i "/^\tln -s \/usr.*/i \\\tln -s \/etc\/nginx\/sites-available\/default.conf \$\(INSTALLDIR\)\/etc\/nginx\/sites-enabled\/default.conf" nginx.rules.in
  echo -e "OK"
fi
cd "${WORKPWD}"
# exit 0;


# Build the package
if [ ! -d "output" ]; then
  mkdir output
else
  rm -Rf output
  mkdir output
fi

docker build -t "docker-deb-builder:${DISTRO_VERSION}" -f "Dockerfile-ubuntu-${DISTRO_VERSION}" .
cd "${WORKPWD}"
./docker.sh -i "docker-deb-builder:${DISTRO_VERSION}" -o output "build/nginx-${NGINX_VERSION}"
./docker.sh -i "docker-deb-builder:${DISTRO_VERSION}" -o output -t "nginx-${NGINX_VERSION}" "build/nginx-${NGINX_VERSION}"
