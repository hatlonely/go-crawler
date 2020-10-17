FROM centos:centos7

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "Asia/Shanghai" >> /etc/timezone

COPY docker/ /var/docker/go-crawler-crawler
RUN mkdir -p /var/docker/go-crawler-crawler/log

WORKDIR /var/docker/go-crawler-crawler
CMD [ "bin/crawler", "-c", "config/shicimingju.json" ]