FROM centos:centos7

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "Asia/Shanghai" >> /etc/timezone

COPY docker/ /var/docker/go-crawler-databus
RUN mkdir -p /var/docker/go-crawler-databus/log

WORKDIR /var/docker/go-crawler-databus
CMD [ "bin/databus", "-c", "config/go-crawler-databus.json" ]