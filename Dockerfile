# syntax=docker/dockerfile:1.17

FROM library/debian:stable-slim AS build

ENV LANG=C.UTF-8 \
    SANDBOX_ROOT=/

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get install -y wget openssl ca-certificates

ADD https://github.com/alemax-xyz/misc-tools.git#main /usr/local/bin/

RUN mkdir -p /build /rootfs

WORKDIR /build

COPY build/ .

COPY --from=clover/busybox:latest /var/lib/packages/ var/lib/packages/

RUN apt-sandbox --install --verstamp \
        --apt-config \
            APT::Install-Recommends=false \
            APT::Get::Upgrade==false \
        --repository . \
        --keyring . \
        --installed var/lib/packages \
        --obsolete packages.obsolete \
        --required packages.required

WORKDIR /rootfs

RUN wget -nv -O usr/bin/tini "https://github.com/krallin/tini/releases/download/v0.19.0/tini-$(dpkg --print-architecture)" \
 && chmod a+x,u+s,g+s usr/bin/tini \
 && printf '%s\n' 'tini=0.19.0' \
 && rm -rf \
        etc/init.d \
        etc/security/namespace.init \
        etc/*/README \
        etc/sudo_logsrvd.conf \
        usr/include \
        usr/lib/systemd \
        usr/lib/tmpfiles.d \
 && mkdir -p \
        etc/skel \
        etc/environment.d \
        etc/cron.hourly \
        etc/cron.daily \
        etc/cron.weekly \
        etc/cron.monthly \
 && ln -s /var/spool/cron/crontabs etc/cron.d \
 && ln -s /var/spool/cron/crontabs/root etc/crontab \
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
 && sed -i -E \
        -e 's,^[[:space:]]*[#]+.*$,,g' \
        -e 's,[[:space:]]+, ,g' \
        -e '/^[[:space:]]*$/d' \
        etc/security/*.conf \
        etc/selinux/*.conf \
        etc/*.conf \
        etc/pam.d/* \
        etc/sudoers \
 && rm -rf usr/share

COPY rootfs/ ./

WORKDIR /

FROM clover/busybox

ENV LANG=C.UTF-8 \
    TINI_KILL_PROCESS_GROUP=1

COPY --from=build /rootfs /

ENTRYPOINT ["/etc/entrypoint"]

CMD ["/etc/run"]
