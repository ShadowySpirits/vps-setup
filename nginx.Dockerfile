FROM ubuntu:bionic

RUN apt update && apt install -y wget
RUN wget https://raw.githubusercontent.com/ShadowySpirits/vps-setup/master/nginx_install.sh -O /nginx_install.sh
RUN chmod +x /nginx_install.sh
RUN /nginx_install.sh --with-waf --enable-iouring --no-service
RUN rm -rf /nginx-src /nginx_install.sh

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
