FROM debian:bullseye-slim as base

SHELL ["/bin/bash", "-c"]

RUN echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/docker-no-recommends
RUN echo 'APT::Install-Suggests   "false";' >> /etc/apt/apt.conf.d/docker-no-suggests

RUN apt-get update
RUN apt-get install -y ca-certificates curl
RUN apt-get install -y procps iptables
RUN apt-get install -y iproute2 iputils-ping dnsutils
RUN apt-get install -y dante-server wireguard-tools

RUN mkdir /wg
WORKDIR /wg

ARG WGNAME="wgcf"
ENV WGNAME=$WGNAME

ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/danted"]

RUN rm -rf /var/lib/apt/lists/*
