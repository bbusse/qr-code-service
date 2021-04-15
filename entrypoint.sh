#!/usr/bin/env sh
set -o errexit

case "$1" in
    sh|bash)
        set -- "$@"
    ;;
    *)
        set -- qr_service
    ;;
esac

exec "$@"
