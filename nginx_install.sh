#!/usr/bin/env bash
vod=false
mkv=false
waf=false
io_uring=false
service=true

ARGS=`getopt -o "ao:" -l "with-vod,enable-mkv,with-waf,enable-iouring,no-service" -n "nginx_install.sh" -- "$@"`
eval set -- "${ARGS}"
while true; do
  case "${1}" in
    --with-vod)
    shift;
    vod=true
    ;;
    --enable-mkv)
    shift;
    mkv=true
    ;;
    --with-waf)
    shift;
    waf=true
    ;;
    --enable-iouring)
    shift;
    io_uring=true
    ;;
    --no-service)
    shift;
    service=false
    ;;
    --)
    shift;
    break;
    ;;
  esac
done

set -euov pipefail
apt update -qq
apt install -y build-essential autoconf automake libatomic-ops-dev libgeoip-dev libbrotli-dev curl git unzip wget

mkdir ~/nginx-src
cd ~/nginx-src

# Nginx 1.21.3
wget -q https://nginx.org/download/nginx-1.21.3.tar.gz
tar zxf nginx-1.21.3.tar.gz && rm nginx-1.21.3.tar.gz

# FULL HPACK, Dynamic TLS Record patch
pushd nginx-1.21.3
curl -s https://raw.githubusercontent.com/kn007/patch/master/nginx.patch | patch -p1
popd

if $io_uring
then
  # io_uring patch
  pushd nginx-1.21.3
  curl -s https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_io_uring.patch | patch -p1
  popd
fi

# OpenSSL 1.1.1d
wget -q https://www.openssl.org/source/openssl-1.1.1d.tar.gz
tar zxf openssl-1.1.1d.tar.gz && rm openssl-1.1.1d.tar.gz

# OpenSSL patch
pushd openssl-1.1.1d
curl -s https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-1.1.1d-chacha_draft.patch | patch -p1
popd

pushd openssl-1.1.1d
curl -s https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-equal-1.1.1d_ciphers.patch | patch -p1
popd

# jemalloc
git clone -q https://github.com/jemalloc/jemalloc.git
pushd jemalloc
./autogen.sh
make -j$(nproc --all)
touch doc/jemalloc.html
touch doc/jemalloc.3
make install
echo '/usr/local/lib' | tee /etc/ld.so.conf.d/local.conf
ldconfig
popd

if $io_uring
then
  # io_uring lib
  git clone -q https://github.com/axboe/liburing.git
  pushd liburing
  make && make install
  popd
fi

# zlib Cloudflare ver
git clone -q -b master https://github.com/cloudflare/zlib.git
pushd zlib
./configure
make && make install
popd

# pcre
wget -q https://ftp.pcre.org/pub/pcre/pcre-8.44.zip
unzip -oq pcre-8.44.zip && rm pcre-8.44.zip
mv pcre-8.44 pcre

# ngx_brotli
git clone -q https://github.com/google/ngx_brotli.git
pushd ngx_brotli
git submodule update --init
popd

# LuaJit
wget -q https://github.com/openresty/luajit2/archive/v2.1-20190626.tar.gz
tar zxf v2.1-20190626.tar.gz && rm v2.1-20190626.tar.gz
mv luajit2-2.1-20190626 luajit-2.1
pushd luajit-2.1
make && make install
ldconfig
popd

export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.1
export LUA_VERSION=5.1
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1

# lua resty core
wget -q https://github.com/openresty/lua-resty-core/archive/v0.1.17.tar.gz
tar zxf v0.1.17.tar.gz && rm v0.1.17.tar.gz
mv lua-resty-core-0.1.17 lua-resty-core
pushd lua-resty-core
make && make install
popd

# lua cjson
wget -q https://github.com/openresty/lua-cjson/archive/2.1.0.7.tar.gz
tar zxf 2.1.0.7.tar.gz && rm 2.1.0.7.tar.gz
mv lua-cjson-2.1.0.7 lua-cjson
pushd lua-cjson
make && make install
popd

# lua resty lrucache
wget -q https://github.com/openresty/lua-resty-lrucache/archive/v0.09.tar.gz
tar zxf v0.09.tar.gz && rm v0.09.tar.gz
mv lua-resty-lrucache-0.09 lua-resty-lrucache
pushd lua-resty-lrucache
make && make install
popd

# lua module
wget -q https://github.com/openresty/lua-nginx-module/archive/v0.10.15.tar.gz
tar zxf v0.10.15.tar.gz && rm v0.10.15.tar.gz
mv lua-nginx-module-0.10.15 lua-nginx-module

# NDK
wget -q https://github.com/simplresty/ngx_devel_kit/archive/v0.3.1rc1.tar.gz
tar zxf v0.3.1rc1.tar.gz && rm v0.3.1rc1.tar.gz
mv ngx_devel_kit-0.3.1rc1 ngx_devel_kit

if $vod
then
  # nginx-vod-module
  wget -q https://github.com/kaltura/nginx-vod-module/archive/1.24.tar.gz
  tar zxf 1.24.tar.gz && rm 1.24.tar.gz
  mv nginx-vod-module-1.24 nginx-vod-module
  if $mkv
  then
    pushd nginx-vod-module
    curl -s https://gist.githubusercontent.com/ShadowySpirits/d2e0e056f838ad204a10e6c38c2375fa/raw/8af12279476cd4feda4e64458e857953eaf12d7c/nginx-vod-module_mkv_support.patch | patch -p1
    popd
  fi
fi

# libmaxminddb
wget -q https://github.com/maxmind/libmaxminddb/releases/download/1.3.2/libmaxminddb-1.3.2.tar.gz
tar zxf libmaxminddb-1.3.2.tar.gz && rm libmaxminddb-1.3.2.tar.gz
mv libmaxminddb-1.3.2 libmaxminddb
pushd libmaxminddb
./configure
make && make install
ldconfig
popd

# ngx_http_geoip2_module
wget -q https://github.com/leev/ngx_http_geoip2_module/archive/3.2.tar.gz
tar zxf 3.2.tar.gz && rm 3.2.tar.gz
mv ngx_http_geoip2_module-3.2 ngx_http_geoip2_module

# nginx-sorted-querystring-module
wget -q https://github.com/wandenberg/nginx-sorted-querystring-module/archive/0.3.tar.gz
tar zxf 0.3.tar.gz && rm 0.3.tar.gz
mv nginx-sorted-querystring-module-0.3 nginx-sorted-querystring-module

# ngx_http_substitutions_filter_module
wget -q https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/v0.6.4.tar.gz
tar zxf v0.6.4.tar.gz && rm v0.6.4.tar.gz
mv ngx_http_substitutions_filter_module-0.6.4 ngx_http_substitutions_filter_module

cd nginx-1.21.3

sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc

if $vod
then
  ./configure \
  --with-cc-opt='-g -O3 -m64 -march=native -ffast-math -DTCP_FASTOPEN=23 -fPIE -fstack-protector-strong -flto -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wno-unused-parameter -fno-strict-aliasing -fPIC -D_FORTIFY_SOURCE=2 -gsplit-dwarf' \
  --with-ld-opt='-lrt -L /usr/local/lib -ljemalloc -Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -fPIC' \
  --user=www-data \
  --group=www-data \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --http-log-path=/home/wwwlogs/access.log \
  --error-log-path=/home/wwwlogs/error.log \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/run/nginx.pid \
  --modules-path=/usr/lib/nginx/modules \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  --with-threads \
  --with-file-aio \
  --with-pcre-jit \
  --with-http_v2_module \
  --with-http_ssl_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_slice_module \
  --with-http_geoip_module \
  --with-http_gunzip_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_gzip_static_module \
  --with-http_degradation_module \
  --with-http_secure_link_module \
  --with-http_stub_status_module \
  --with-http_random_index_module \
  --with-http_auth_request_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-stream_realip_module \
  --with-http_v2_hpack_enc \
  --with-pcre=../pcre \
  --with-zlib=../zlib \
  --with-libatomic \
  --with-openssl=../openssl-1.1.1d \
  --with-openssl-opt='zlib -march=native -ljemalloc -Wl,-flto' \
  --add-module=../ngx_brotli \
  --add-module=../ngx_devel_kit \
  --add-module=../lua-nginx-module \
  --add-module=../ngx_http_geoip2_module \
  --add-module=../nginx-sorted-querystring-module \
  --add-module=../ngx_http_substitutions_filter_module \
  --add-module=../nginx-vod-module
else
  ./configure \
  --with-cc-opt='-g -O3 -m64 -march=native -ffast-math -DTCP_FASTOPEN=23 -fPIE -fstack-protector-strong -flto -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wno-unused-parameter -fno-strict-aliasing -fPIC -D_FORTIFY_SOURCE=2 -gsplit-dwarf' \
  --with-ld-opt='-lrt -L /usr/local/lib -ljemalloc -Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -fPIC' \
  --user=www-data \
  --group=www-data \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --http-log-path=/home/wwwlogs/access.log \
  --error-log-path=/home/wwwlogs/error.log \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/run/nginx.pid \
  --modules-path=/usr/lib/nginx/modules \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  --with-threads \
  --with-file-aio \
  --with-pcre-jit \
  --with-http_v2_module \
  --with-http_ssl_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_slice_module \
  --with-http_geoip_module \
  --with-http_gunzip_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_gzip_static_module \
  --with-http_degradation_module \
  --with-http_secure_link_module \
  --with-http_stub_status_module \
  --with-http_random_index_module \
  --with-http_auth_request_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-stream_realip_module \
  --with-http_v2_hpack_enc \
  --with-pcre=../pcre \
  --with-zlib=../zlib \
  --with-libatomic \
  --with-openssl=../openssl-1.1.1d \
  --with-openssl-opt='zlib -march=native -ljemalloc -Wl,-flto' \
  --add-module=../ngx_brotli \
  --add-module=../ngx_devel_kit \
  --add-module=../lua-nginx-module \
  --add-module=../ngx_http_geoip2_module \
  --add-module=../nginx-sorted-querystring-module \
  --add-module=../ngx_http_substitutions_filter_module
fi

make -j$(nproc --all)
make install

# ngx_lua_waf
cd /etc/nginx
if $waf
then
  git clone -q https://github.com/xzhih/ngx_lua_waf.git waf 
  mkdir -p /home/wwwlogs/waf
fi
mkdir -p /home/wwwroot
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/conf.d
mkdir -p /var/lib/nginx/body
chown -R www-data:www-data /home/wwwlogs
chown -R www-data:www-data /home/wwwroot

if $waf
then
  tee /etc/nginx/waf/config.lua << EOF
config_waf_enable = "on"
config_log_dir = "/home/wwwlogs/waf"
config_rule_dir = "/etc/nginx/waf/wafconf"
config_white_url_check = "on"
config_white_ip_check = "on"
config_black_ip_check = "on"
config_url_check = "on"
config_url_args_check = "on"
config_user_agent_check = "on"
config_cookie_check = "on"
config_cc_check = "on"
config_cc_rate = "180/30" -- count per XX seconds
config_post_check = "on"
config_waf_output = "html"
config_waf_redirect_url = "/captcha" -- only enable when config_waf_output = "redirect"
config_output_html=[[
<html><head><meta name="viewport"content="initial-scale=1,minimum-scale=1,width=device-width"><title>WAF Alert</title><style>body{font-size:100%;background-color:#ce3426;color:#fff;margin:15px}@media(max-width:420px){body{font-size:90%}}</style></head><body><div style=""><div style=" text-align: center;margin-top: 250px;"><h1>WAF</h1><h2>Your request has been blocked</h2></div></div></body></html>
]]
EOF


  tee /etc/nginx/conf.d/waf.conf << EOF
lua_shared_dict limit 20m;
lua_package_path "/usr/local/lib/lua/5.1/?.lua;/etc/nginx/waf/?.lua";
init_by_lua_file "/etc/nginx/waf/init.lua";
access_by_lua_file "/etc/nginx/waf/access.lua";
EOF
fi

# nginx conf
tee /etc/nginx/nginx.conf << EOF
user www-data www-data;
pid /run/nginx.pid;
worker_processes auto;
worker_rlimit_nofile 65535;

events {
  use epoll;
  multi_accept on;
  worker_connections 65535;
}

http {
  charset utf-8;
  sendfile off;
  tcp_nopush on;
  tcp_nodelay on;
  aio on;
  server_tokens off;
  log_not_found off;
  types_hash_max_size 2048;
  client_max_body_size 0;
  client_header_buffer_size 4k;

  # SSL
  ssl_session_cache           shared:SSL:30m;
  ssl_session_timeout         1d;
  ssl_session_tickets         off;

  ssl_stapling on;
  ssl_stapling_verify on;
  resolver 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 valid=60s;
  resolver_timeout 2s;

  ssl_protocols               TLSv1.2 TLSv1.3;
  ssl_ecdh_curve              X25519:P-256:P-384:P-224:P-521;
  ssl_ciphers                 [TLS_AES_256_GCM_SHA384|TLS_AES_128_GCM_SHA256|TLS_CHACHA20_POLY1305_SHA256]:[ECDHE-ECDSA-AES128-GCM-SHA256|ECDHE-ECDSA-CHACHA20-POLY1305|ECDHE-RSA-AES128-GCM-SHA256|ECDHE-RSA-CHACHA20-POLY1305]:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
  ssl_prefer_server_ciphers   on;
  ssl_early_data              on;
  proxy_set_header            Early-Data \$ssl_early_data;

  # MIME
  include mime.types;
  default_type application/octet-stream;

  # Logging
  access_log /home/wwwlogs/access.log;
  error_log /home/wwwlogs/error.log;

  # Gzip
  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
  gzip_disable "MSIE [1-6]\.(?!.*SV1)";

  # Brotli
  brotli on;
  brotli_static on;
  brotli_min_length 20;
  brotli_buffers 32 8k;
  brotli_comp_level 6;
  brotli_types text/plain text/css text/xml text/javascript application/javascript application/x-javascript application/json application/xml application/rss+xml application/atom+xml image/svg+xml;

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}
EOF

if $service
then
  # nginx service
  tee /lib/systemd/system/nginx.service <<EOF
[Unit]
Description=A high performance web server and a reverse proxy server
After=network.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

  systemctl unmask nginx.service
  systemctl daemon-reload
  systemctl enable nginx
  systemctl start nginx
  systemctl status nginx
fi
