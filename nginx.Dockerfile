FROM ubuntu:bionic

COPY nginx_install.sh /

RUN chmod +x /nginx_install.sh
RUN /nginx_install.sh --with-waf --enable-iouring --no-service
RUN rm -rf /root/nginx-src

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
