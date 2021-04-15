# qr-code-service
A k8s ready http service for QR code generation  
  
[![GitHub Super-Linter](https://github.com/bbusse/qr-code-service/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
&nbsp;![Docker Build](https://github.com/bbusse/qr-code-service/actions/workflows/docker-image.yml/badge.svg)
&nbsp;![Tests](https://github.com/bbusse/qr-code-service/actions/workflows/make-test.yml/badge.svg)
  
![QR-Code](qr-code.png "QR code")  
  
## Endpoints
- /encode  Generate and return qr-code png
- /delete  Delete all files
- /files   List available files
- /metrics Prometheus metrics endpoint
- /healthy
- /healthz 

## Usage
### Run service
```bash
$ ./qr_service --help
usage: qr_service [-h] [--listen-address LISTEN_ADDRESS]
                  [--listen-port LISTEN_PORT] [--disable-delete-files]
                  [--disable-list-files] [--debug]

optional arguments:
  -h, --help            show this help message and exit
  --listen-address LISTEN_ADDRESS
                        The address to listen on
  --listen-port LISTEN_PORT
                        The port to listen on
  --disable-delete-files
                        Disable file deletion
  --disable-list-files  Disable file listing
  --debug               Show debug output
```
### Run container
```bash
$ podman run
[output]
```
### Create QR-Code
A GET request to the **/encode** endpoint with optional **url**, **size** and **margin** parameters to encode the given URL immediately returns a png encoded image file
```bash
$ export LISTEN_ADDRESS=localhost; \
  export LISTEN_PORT=44123; \
  export URL=https://[::1]; \
  export SIZE=20; \
  curl -O http://${LISTEN_ADDRESS}:${LISTEN_PORT}/encode?url={${URL}&size=${SIZE}
```
Generated files land in the static/ directory and can also be fetched from there.  
The directory does not get emptied automatically.  
A request to **/delete** removes all png files in this location, if enabled

### List generated files on server
A call to the **/files** endpoint returns JSON containing all present png files at the static location
```bash
$ export LISTEN_ADDRESS=localhost; \
  export LISTEN_PORT=44123; \
  curl http://${LISTEN_ADDRESS}:${LISTEN_PORT}/files
```
### Clean-up files on server
A call to the **/delete** endpoint deletes all present png files at the static location
```bash
$ export LISTEN_ADDRESS=localhost; \
  export LISTEN_PORT=44123; \
  curl http://${LISTEN_ADDRESS}:${LISTEN_PORT}/delete
```

### Metrics
A **/metrics** endpoint for Prometheus exists
```bash
$ export LISTEN_ADDRESS=localhost; \
  export LISTEN_PORT=44123; \
  curl http://${LISTEN_ADDRESS}:${LISTEN_PORT}/metrics
```

### Run tests
[bash_unit](https://github.com/pgrange/bash_unit) is used to run the test
```bash
$ make test
./tests/install_bash_unit.sh
bash_unit test framework exists
./bash_unit
./bash_unit tests/test_qr_service.sh
Running tests in tests/test_qr_service.sh
Starting qr-service
Running test_qr_delete... SUCCESS ✓
Running test_qr_encode... SUCCESS ✓
Running test_qr_list... SUCCESS ✓
Running test_qr_service_running... SUCCESS ✓
Stopping qr-service (55036)
```

## References
[Wikipedia: QR code](https://en.wikipedia.org/wiki/QR_code)  
[libqrencode](https://github.com/fukuchi/libqrencode)
