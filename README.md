# vps shell

Useful scripts for vps management

## nginx_install.sh

install nginx 1.17.1 with TLS1.3 and Strict-SNI support

use it as follow:
```
curl https://raw.githubusercontent.com/ShadowySpirits/vps-shell/master/nginx_install.sh | bash
```


### parameter
- --with-vod &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: add nginx-vod-module
- --enable-mkv &nbsp;&nbsp;: enable mkv support for nginx-vod-module (experimental function)
- --with-waf &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: add lua waf


## deluge_install.sh

install deluge and deluge-webui

use it as follow:
```
curl https://raw.githubusercontent.com/ShadowySpirits/vps-shell/master/deluge_install.sh | sudo bash
```


## get_gfwlist.sh

download gfw domain list

use it as follow:
```
curl https://raw.githubusercontent.com/ShadowySpirits/vps-shell/master/get_gfwlist.sh | bash
```
