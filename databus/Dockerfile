FROM centos:centos7

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "Asia/Shanghai" >> /etc/timezone

COPY docker/ /var/docker/go-crawler-analyst
RUN mkdir -p /var/docker/go-crawler-analyst/log

WORKDIR /var/docker/go-crawler-analyst
CMD [ "bin/analyst", "-c", "config/shicimingju.json" ]