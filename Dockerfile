ARG ALPINE_VERSION=3.13.5
FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Björn Busse <bj.rn@baerlin.eu>"
LABEL org.opencontainers.image.source=https://github.com/bbusse/qr-code-service

ENV ARCH="x86_64" \
    USER="qr" \
    APK_ADD="python3~=3 py3-pip~=20 libqrencode~=4" \
    APK_DEL=""

# Add packages
USER root

# Add application user and application
# Cleanup: Remove files and users
RUN addgroup -S $USER && adduser -S $USER -G $USER \
    # https://gitlab.alpinelinux.org/alpine/aports/-/issues/11768
    && sed -i -e 's/https/http/' /etc/apk/repositories \
    && apk add --no-cache ${APK_ADD} \
    && apk del --no-cache ${APK_DEL} \
    && rm -rf \
      /usr/share/man/* \
      /usr/includes/* \
      /var/cache/apk/* \
    && deluser --remove-home daemon \
    && deluser --remove-home adm \
    && deluser --remove-home lp \
    && deluser --remove-home sync \
    && deluser --remove-home shutdown \
    && deluser --remove-home halt \
    && deluser --remove-home postmaster \
    && deluser --remove-home cyrus \
    && deluser --remove-home mail \
    && deluser --remove-home news \
    && deluser --remove-home uucp \
    && deluser --remove-home operator \
    && deluser --remove-home man \
    && deluser --remove-home cron \
    && deluser --remove-home ftp \
    && deluser --remove-home sshd \
    && deluser --remove-home at \
    && deluser --remove-home squid \
    && deluser --remove-home xfs \
    && deluser --remove-home games \
    && deluser --remove-home vpopmail \
    && deluser --remove-home ntp \
    && deluser --remove-home smmsp \
    && deluser --remove-home guest

# Add entrypoint
USER $USER
COPY qr_service /usr/local/bin
COPY requirements.txt /
RUN pip3 install --no-cache-dir --user -r requirements.txt
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
