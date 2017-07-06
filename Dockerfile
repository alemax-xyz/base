FROM library/ubuntu:xenial AS build

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
RUN apt-get update && \
    apt-get install -y \
        python-software-properties \
        software-properties-common \
        apt-utils \
        wget

RUN mkdir -p /build/image
WORKDIR /build
RUN apt-get download \
        libselinux1 \
        libsemanage1 \
        libsemanage-common \
        libsepol1 \
        libpam0g \
        libpam-modules \
        libpam-modules-bin \
        libaudit1 \
        libaudit-common \
        libbz2-1.0 \
        libdb5.3 \
        libpcre3 \
        libustr-1.0-1 \
        passwd
RUN wget https://github.com/krallin/tini/releases/download/v0.15.0/tini_0.15.0-amd64.deb
RUN for file in *.deb; do dpkg-deb -x ${file} image/; done

WORKDIR /build/image
RUN rm -rf \
        etc/cron.daily \
        etc/default \
        etc/init \
        etc/security \
        usr/bin/tini-static \
        usr/lib/tmpfiles.d \
        usr/share


FROM clover/busybox

WORKDIR /
COPY --from=build /build/image /

ENTRYPOINT ["tini", "--"]

CMD ["sh"]
