[![GitHub Super-Linter](https://github.com/bbusse/qr-service/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
# qr-service
An http service for QR-Code generation  
![QR-Code](qr-code.png "QR Code")
## Endpoints
- /encode Generate and return qr-code png
- /delete Delete all files
- /files  List available files

## Usage
```
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
### Create QR-Code
A GET request to the **/encode** endpoint with optional **url**, **size** and **margin** parameters to encode the given URL immediately returns a png encoded image file
```
$ export LISTEN_ADDRESS=localhost; \
  export LISTEN_PORT=44123; \
  export URL=https://[::1]; \
  export SIZE=20; \
  curl -O http://${LISTEN_ADDRESS}:${LISTEN_PORT}/encode?url={${URL}&size=${SIZE}
```
Generated files land in the static/ directory and can also be fetched from there.  
The directory does not get emptied automatically.  
A request to **/delete** removes all png files in this location, if enabled

### Clean-up
A call to the **/delete** endpoint deletes all present png files at the static location
```
$ export LISTEN_ADDRESS=localhost; \
  export LISTEN_PORT=44123; \
  curl http://${LISTEN_ADDRESS}:${LISTEN_PORT}/delete
```

## Metrics
A **/metrics** endpoint for Prometheus exists
```
$ export LISTEN_ADDRESS=localhost; \
  export LISTEN_PORT=44123; \
  curl http://${LISTEN_ADDRESS}:${LISTEN_PORT}/metrics
```


## References
[libqrencode](https://github.com/fukuchi/libqrencode)
