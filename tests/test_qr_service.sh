#!/usr/bin/env bash

setup_suite() {
    run_service
}

run_service() {
    printf "Starting qr-service\n"
    cd ../ || exit
    ./qr_service > /dev/null 2>&1 &
    PID=$!
    sleep 5
}

test_qr_service_running() {
    assert "nc -n -w1 \"${1:-\"127.0.0.1\"}\" \"${2:-\"44123\"}\"" "qr: Service not running"
}

test_qr_encode() {
    png=$(curl -s "http://localhost:44123/encode?url=http://github.com/bbusse/qr-service&size=15&margin=2")
    md5sum=$(echo "$png" | md5)
    assert_equals "824dd62f5c5e2b1da68b1853712bb9e5" "$md5sum" "qr: Receiving qr-code file failed"
}

test_qr_list() {
    $(touch static/0a52ee86bcd81feccf8641735563ac3f_15_2.png)
    r=$(curl -s http://localhost:44123/files)
    assert_equals "[\"0a52ee86bcd81feccf8641735563ac3f_15_2.png\"]" "$r" "qr: File listing failed"
}

test_qr_delete() {
    r=$(curl -s http://localhost:44123/delete)
    assert_equals "OK" "$r" "qr: File deletion failed"
}

teardown_suite() {
    printf "Stopping qr-service (%s)\n" "$PID"
    if ! kill $PID > /dev/null 2>&1; then
        printf "Failed to send SIGTERM to %s\n" "$PID"
    fi
}
