FROM library/debian:stable-slim AS build

ENV LANG=C.UTF-8

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get install -y \
        wget

RUN mkdir /build /rootfs
WORKDIR /build
RUN apt-get download \
        zlib1g \
        libacl1 \
        libapparmor1 \
        libattr1 \
        libbsd0 \
        libcrypt1 \
        libmd0 \
        libselinux1 \
        libsemanage2 \
        libsemanage-common \
        libsepol2 \
        libssl3t64 \
        libsystemd0 \
        libpam0g \
        libpam-modules \
        libpam-modules-bin \
        libaudit1 \
        libaudit-common \
        libcap-ng0 \
        libcap2 \
        libbz2-1.0 \
        libdb5.3t64 \
        libpcre2-8-0 \
        libpam-runtime \
        libzstd1 \
        sudo \
        passwd \
        cron \
        cron-daemon-common
RUN find . -name '*.deb' -exec dpkg-deb -x {} /rootfs \;

WORKDIR /rootfs

RUN rm -rf \
        etc/cron*/.placeholder \
        etc/default/* \
        etc/init.d \
        etc/security/namespace.init \
        etc/*/README \
        etc/sudo_logsrvd.conf \
        etc/supercat \
        usr/include \
        usr/lib/systemd \
        usr/lib/sysusers.d \
        usr/lib/tmpfiles.d \
        usr/sbin/pam* \
        usr/sbin/shadowconfig \
 && mkdir -p \
        etc/skel \
 && sed -i -r \
        's,test -x /usr/sbin/anacron [|][|] [{] | ?;? ?[}]| --report,,g' \
        etc/crontab \
 && sed -i -r \
        -e '/^ *%.*$/d' \
        -e '/^[[:space:]]*Defaults[[:space:]]+mail_badpass.*$/d' \
        etc/sudoers \
 && sed \
        -e 's/\$account_primary/account [success=1 new_authtok_reqd=done default=ignore] pam_unix.so/g' \
        -e 's/\$account_additional//g' \
        usr/share/pam/common-account > etc/pam.d/common-account \
 && sed \
        -e 's/\$auth_primary/auth [success=1 default=ignore] pam_unix.so nullok_secure/g' \
        -e 's/\$auth_additional//g' \
        usr/share/pam/common-auth > etc/pam.d/common-auth \
 && sed \
        -e 's/\$password_primary/password [success=1 default=ignore] pam_unix.so obscure sha512/g' \
        -e 's/\$password_additional//g' \
        usr/share/pam/common-password > etc/pam.d/common-password \
 && sed \
        -e 's/\$session_primary/session [default=1] pam_permit.so/g' \
        -e 's/\$session_additional/session required pam_unix.so/g' \
        usr/share/pam/common-session > etc/pam.d/common-session \
 && sed \
        -e 's/\$session_nonint_primary/session [default=1] pam_permit.so/g' \
        -e 's/\$session_nonint_additional/session required pam_unix.so/g' \
        usr/share/pam/common-session-noninteractive > etc/pam.d/common-session-noninteractive \
 && echo 'LANG=C.UTF-8' > etc/default/locale \
 && (echo '#!/bin/sh'; echo 'exec /bin/vi "$*"') > usr/bin/sensible-editor \
 && chmod +x usr/bin/sensible-editor \
 && find \
        etc/security/*.conf \
        etc/selinux/*.conf \
        etc/*.conf \
        etc/crontab \
        etc/pam.d/* \
        etc/sudoers \
    | xargs -I % sed -i -r \
        -e 's,^[[:space:]]*[#]+.*$,,g' \
        -e 's,[[:space:]]+, ,g' \
        -e '/^[[:space:]]*$/d' \
        % \
 && rm -rf \
        usr/share

RUN wget --no-check-certificate -nv -O usr/bin/tini https://github.com/krallin/tini/releases/download/v0.19.0/tini-`dpkg --print-architecture` \
 && chmod a+x usr/bin/tini

COPY etc/ etc/

WORKDIR /


FROM clover/busybox

ENV LANG=C.UTF-8

COPY --from=build /rootfs /

ENTRYPOINT ["tini", "--", "sh", "/etc/entrypoint.sh"]

CMD ["sh", "/etc/init.sh"]
