#!/usr/bin/env bash

setup_suite() {
    run_service
}

run_service() {
    printf "Starting qr-service\n"
    cd ../ || exit
    ./qr_service > /dev/null 2>&1 &
    PID=$!
    sleep 2
}

test_qr_service_running() {
    assert "nc -n -w1 \"${1:-\"127.0.0.1\"}\" \"${2:-\"44123\"}\"" "qr: Service not running"
}

test_qr_encode() {
    if ! command -v md5 &> /dev/null
    then
        cmd="md5sum"
        md5_expected="4f854cd7f43689b5ac552528a402d2b0"
    else
        cmd="md5 -q"
        md5_expected="d66a1f47df6043dcf9850613521f9507"
    fi

    testfile="qr-code-test.png"
    [ -e testfile ] && rm testfile
    curl -s -o ${testfile} "http://localhost:44123/encode?url=http://github.com/bbusse/qr-service&size=15&margin=2"
    md5sum=$($cmd ${testfile})
    [ -e testfile ] && rm testfile
    assert_equals "$md5_expected" "$md5sum" "qr: Receiving qr-code file failed"
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

teardown_suite() {
    printf "Stopping qr-service (%s)\n" "$PID"
    if ! kill $PID > /dev/null 2>&1; then
        printf "Failed to send SIGTERM to %s\n" "$PID"
    fi
}
