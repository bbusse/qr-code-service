#!/usr/bin/env bash

setup_suite() {
    run_service
}

run_service() {
    printf "Starting qr-code-service\n"
    cd ../ || exit
    ./qr_service > /dev/null 2>&1 &
    PID=$!
    sleep 2
}

test_qr_service_running() {
    assert "nc -n -w1 \"${1:-\"127.0.0.1\"}\" \"${2:-\"44123\"}\"" "qr: Service not running"
}

test_qr_encode() {
    local testfile="qr-code-test.png"

    if ! command -v md5 &> /dev/null
    then
        cmd="md5sum"
        md5_expected="d66a1f47df6043dcf9850613521f9507  ${testfile}"
    else
        cmd="md5 -q"
        md5_expected="d66a1f47df6043dcf9850613521f9507"
    fi

    [ -e testfile ] && rm testfile
    curl -s -o ${testfile} "http://localhost:44123/encode?url=http://github.com/bbusse/qr-service&size=15&margin=2"
    md5sum=$($cmd ${testfile})
    mimetype=$(file -i ${testfile})
    [ -e testfile ] && rm testfile
    assert_equals "$md5_expected" "$md5sum" "qr: Receiving qr-code file failed"
    assert_equals "${testfile}: image/png; charset=binary" "$mimetype" "qr: ${testfile} is not a png image"
}

test_qr_list() {
    touch static/0a52ee86bcd81feccf8641735563ac3f_15_2.png
    r=$(curl -s http://localhost:44123/files)
    assert_equals "[\"0a52ee86bcd81feccf8641735563ac3f_15_2.png\"]" "$r" "qr: File listing failed"
}

test_qr_delete() {
    r=$(curl -s http://localhost:44123/delete)
    assert_equals "OK" "$r" "qr: File deletion failed"
}

test_qr_healthy() {
    r=$(curl -s http://localhost:44123/healthy)
    assert_equals "OK" "$r" "qr: health check for readiness failed"
}

test_qr_healthz() {
    r=$(curl -s http://localhost:44123/healthz)
    assert_equals "OK" "$r" "qr: health check for liveness failed"
}

teardown_suite() {
    printf "Stopping qr-code-service (%s)\n" "$PID"
    if ! kill $PID > /dev/null 2>&1; then
        printf "Failed to send SIGTERM to %s\n" "$PID"
    fi
}
