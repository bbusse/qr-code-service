# qr-code-service on moonshine-python: no busybox, no shell but brush, and
# python3 from the base image
ARG MOONSHINE_PYTHON_VERSION=latest
ARG BASE_IMAGE=ghcr.io/bbusse/moonshine-python:${MOONSHINE_PYTHON_VERSION}

# The venv is built in a stage of its own so pip does not survive into the
# result. python3 seeds it from its own bundled ensurepip wheels, so the
# py3-pip package is not needed at all
FROM ${BASE_IMAGE} AS build
COPY requirements.txt pyproject.toml README.md LICENSE /src/
COPY src /src/src
RUN python3 -m venv /venv \
    && /venv/bin/pip install --disable-pip-version-check --no-cache-dir \
         -r /src/requirements.txt \
    && /venv/bin/pip install --disable-pip-version-check --no-cache-dir /src \
    && rm -rf /venv/lib/python3.*/site-packages/pip \
              /venv/lib/python3.*/site-packages/setuptools \
              /venv/lib/python3.*/site-packages/wheel

FROM ${BASE_IMAGE}
LABEL maintainer="Björn Busse <bj.rn@baerlin.eu>"
LABEL org.opencontainers.image.source=https://github.com/bbusse/qr-code-service

ENV USER="qr" \
    APK_ADD="libqrencode-tools" \
    PATH_VENV="/venv" \
    PATH="/venv/bin:${PATH}"

USER root

# The encoder shells out to qrencode. The base has no adduser -- that comes
# with busybox, which moonshine does not ship -- so the account is written
# out directly, and static/ is where encoded codes are cached
RUN apk add --no-cache ${APK_ADD} \
    && echo "${USER}:x:1000:1000::/home/${USER}:/sbin/nologin" >> /etc/passwd \
    && echo "${USER}:x:1000:" >> /etc/group \
    && mkdir -p /home/${USER} /usr/local/bin/static \
    && chown -R 1000:1000 /home/${USER} /usr/local/bin/static \
    && rm -rf /var/cache/apk/*

COPY --from=build /venv /venv
COPY qr_service /usr/local/bin/qr_service
COPY entrypoint.sh /

USER $USER
WORKDIR /home/qr
ENTRYPOINT ["/entrypoint.sh"]
