FROM centos:centos7

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "Asia/Shanghai" >> /etc/timezone

COPY docker/ /var/docker/crawler
RUN mkdir -p /var/docker/crawler/log

WORKDIR /var/docker/crawler
CMD [ "bin/crawler", "-c", "config/shicimingju.json" ]