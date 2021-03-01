FROM ubuntu:bionic
  
RUN apt update -qq && apt install -y wget
RUN wget -q https://raw.githubusercontent.com/ShadowySpirits/vps-setup/master/nginx_install.sh -O /root/nginx_install.sh
RUN chmod +x /root/nginx_install.sh

RUN /root/nginx_install.sh --with-waf --enable-iouring --no-service

RUN rm -rf /root/nginx-src /root/nginx_install.sh
RUN apt purge -y build-essential autoconf automake libatomic-ops-dev libbrotli-dev git unzip && apt autoremove -y

CMD /usr/sbin/nginx -g 'daemon off;'
