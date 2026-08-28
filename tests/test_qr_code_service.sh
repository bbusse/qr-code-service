#!/usr/bin/env bash

setup_suite() {
    run_service
}

run_service() {
    printf "Starting qr-code-service\n"
    cd ../ || exit
    ./qr_service >/dev/null 2>&1 &
    PID=$!
    sleep 2
}

test_qr_service_running() {
    assert "nc -n -w1 \"${1:-\"127.0.0.1\"}\" \"${2:-\"44123\"}\"" "qr: Service not running"
}

test_qr_encode() {
    local testfile="qr-code-test.png"

    [ -e "$testfile" ] && rm "$testfile"
    curl -s -o "$testfile" "http://localhost:44123/encode?url=http://github.com/bbusse/qr-service&size=15&margin=2"

    # Checked by shape, not by checksum: the encoder's exact bytes move with
    # the segno version, and a test that fails on a dependency bump tells you
    # nothing about this service. The signature is also why file(1) is not
    # used - its -i output differs between GNU and BSD userland.
    bytes=$(wc -c <"$testfile" | tr -d ' ')
    signature=$(head -c 8 "$testfile" | od -An -tx1 | tr -d ' \n')

    assert_equals "89504e470d0a1a0a" "$signature" "qr: ${testfile} lacks the png signature"
    assert "[ \"$bytes\" -gt 100 ]" "qr: ${testfile} is suspiciously small (${bytes} bytes)"

    [ -e "$testfile" ] && rm "$testfile"
}

test_qr_encode_rejects_a_bad_size() {
    code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:44123/encode?url=http://example.invalid&size=abc")
    assert_equals "400" "$code" "qr: a non-integer size should be a 400, not a 404"
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
    if ! kill "$PID" >/dev/null 2>&1; then
        printf "Failed to send SIGTERM to %s\n" "$PID"
    fi
}
