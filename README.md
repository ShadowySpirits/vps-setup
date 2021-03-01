# vps setup

Useful scripts for vps management

## nginx_install.sh

install nginx 1.19.7 with TLS1.3 & WAF & io_uring support

use it as follow:
```
curl https://raw.githubusercontent.com/ShadowySpirits/vps-setup/master/nginx_install.sh | sudo bash
```


### parameter
- --with-vod &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: add nginx-vod-module
- --enable-mkv &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: enable mkv support for nginx-vod-module (experimental function)
- --with-waf &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: add lua waf
- --enable-iouring &nbsp;&nbsp;: use io_uring instead of aio, need linux kernel 5.1+
- --no-service &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: disable creating service automatically

### build docker image
```
wget https://raw.githubusercontent.com/ShadowySpirits/vps-setup/master/nginx.Dockerfile
docker build -t my_nginx:v1.19.7 -f nginx.Dockerfile .
```

## deluge_install.sh

install deluge and deluge-webui

use it as follow:
```
curl https://raw.githubusercontent.com/ShadowySpirits/vps-setup/master/deluge_install.sh | sudo bash
```


## get_gfwlist.sh

download gfw domain list

use it as follow:
```
curl https://raw.githubusercontent.com/ShadowySpirits/vps-setup/master/get_gfwlist.sh | bash
```
