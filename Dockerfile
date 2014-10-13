FROM ubuntu:12.04
RUN useradd -r -s /bin/false varnish
RUN apt-get -q -y update

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get install -q -y apt-transport-https curl

RUN curl https://repo.varnish-cache.org/ubuntu/GPG-key.txt | apt-key add -
RUN echo "deb https://repo.varnish-cache.org/ubuntu/ precise varnish-4.0" >> /etc/apt/sources.list.d/varnish-cache.list

RUN apt-get -q -y update
RUN apt-get install -q -y varnish

ADD default.vcl /etc/varnish/vcl/default.vcl

ENV VARNISH_BACKEND_PORT 80
ENV VARNISH_BACKEND_IP 172.17.42.1
ENV VARNISH_PORT 80

EXPOSE 80

ADD start /start
RUN chmod 0755 /start
CMD ["/start"]
