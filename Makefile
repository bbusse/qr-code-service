ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

all:

release:
    $(shell git rev-list --count HEAD > VERSION)

install: qr_service
	install -d $(DESTDIR)$(PREFIX)/bin/
	install -m 644 qr_service $(DESTDIR)$(PREFIX)/bin/

test:
	./tests/install_bash_unit.sh
	./bash_unit
	./bash_unit tests/test_qr_service.sh

clean:
	rm -rf static/*png
