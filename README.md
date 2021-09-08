## Synopsis

Nginx-builder is a set of scripts able to compile Nginx for Ubuntu/Debian with additional modules such as HTTP2, PageSpeed, Brotli, More Headers, Cache Purge, VTS, GeoIP2, Echo. It's compiled inside 
a docker image using recent GCC version and latest OpenSSL sources. It also includes some built-in configurations such as WordPress and Laravel php-fpm setup. Everything with optional switches in the 
config file.

The idea for this project was inspired by [nginx-more](https://github.com/karljohns0n/nginx-more/).

## Modules

*   [OpenSSL](https://github.com/openssl/openssl)
*   [PageSpeed](https://github.com/apache/incubator-pagespeed-ngx)
*   [Brotli](https://github.com/google/ngx_brotli)
*   [Virtual host traffic status](https://github.com/vozlt/nginx-module-vts)
*   [Headers more](https://github.com/openresty/headers-more-nginx-module)
*   [Cache purge](https://github.com/FRiCKLE/ngx_cache_purge)
*   [GeoIP2](https://github.com/leev/ngx_http_geoip2_module)
*   [Echo](https://github.com/openresty/echo-nginx-module)
*   [ModSecurity](https://github.com/SpiderLabs/ModSecurity-nginx)

## Patches

*   [Cloudflare TLS Dynamic Record](https://blog.cloudflare.com/optimizing-tls-over-tcp-to-reduce-latency/)
*   [Cloudflare full HPACK implementation](https://blog.cloudflare.com/hpack-the-silent-killer-feature-of-http-2/)

## Usage

Be sure docker is installed.

```bash
$ sudo apt install docker.io
$ sudo usermod -aG docker $USER
$ sudo setfacl -m user:$USER:rw /var/run/docker.sock
```

Then run the full compile process with :
```bash
$ ./nginx-build.sh
```

The resulting package can be installed using apt, it will pick it up as nginx and thus provide all normal dependencies.
```bash
$ cd output
$ sudo apt install ./nginx_1.21.2-1~focal_amd64.deb
```
Package name will differ depending version/distribution ofcourse.
