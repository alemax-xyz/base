#
# This is a multi-stage build.
# Actual build is at the very end.
#

FROM library/ubuntu:xenial AS build

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

RUN apt-get update && \
    apt-get install -y \
        python-software-properties \
        software-properties-common \
        apt-utils
RUN apt-get install -y \
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
        libpam-runtime \
        passwd \
        cron
RUN wget https://github.com/krallin/tini/releases/download/v0.16.1/tini_0.16.1-amd64.deb
RUN for file in *.deb; do dpkg-deb -x ${file} image/; done

WORKDIR /build/image
RUN rm -rf \
        etc/cron*/* \
        etc/cron*/.placeholder \
        etc/default/* \
        etc/init \
        etc/init.d \
        etc/security/namespace.init \
        sbin/shadowconfig \
        lib/systemd \
        usr/bin/tini-static \
        usr/lib/tmpfiles.d \
        usr/sbin/pam* \
        usr/share/bug \
        usr/share/doc \
        usr/share/lintian \
        usr/share/man \
        usr/share/pam/*.md5sums && \
    sed -i -r \
        's,test -x /usr/sbin/anacron [|][|] [(] | [)],,g' \
        etc/crontab && \
    for file in usr/share/pam/*; do \
        sed \
            -e 's/\$account_primary/account [success=1 new_authtok_reqd=done default=ignore] pam_unix.so/g' \
            -e 's/\$account_additional//g' \
            -e 's/\$auth_primary/auth [success=1 default=ignore] pam_unix.so nullok_secure/g' \
            -e 's/\$auth_additional//g' \
            -e 's/\$password_primary/password [success=1 default=ignore] pam_unix.so obscure sha512/g' \
            -e 's/\$password_additional//g' \
            -e 's/\$session_primary/session [default=1] pam_permit.so/g' \
            -e 's/\$session_additional/session required pam_unix.so/g' \
            -e 's/\$session_nonint_primary/session [default=1] pam_permit.so/g' \
            -e 's/\$session_nonint_additional/session required pam_unix.so/g' \
            "${file}" > etc/pam.d/$(basename ${file}); \
    done && \
    rm -rf \
        usr/share && \
    for file in etc/security/*.conf etc/selinux/*.conf etc/*.conf etc/crontab etc/pam.d/*; do \
        sed -i -r \
            -e 's,^([ #]+.*|)$,,g' \
            -e '/$^/d' \
            -e 's,[[:space:]]+, ,g' \
            "${file}"; \
    done && \
    echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' > etc/environment && \
    echo 'LANG=C.UTF-8' > etc/default/locale && \
    (echo '#!/bin/sh'; echo '/bin/vi $*') > usr/bin/sensible-editor && \
    chmod +x usr/bin/sensible-editor


FROM clover/busybox

WORKDIR /
COPY --from=build /build/image /

ENTRYPOINT ["tini", "--"]

CMD ["sh"]
