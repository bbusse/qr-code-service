web_static_path := static/

all:

release:
    $(shell git rev-list --count HEAD > VERSION)

test:
	./tests/install_bash_unit.sh
	./bash_unit
	./bash_unit tests/test_qr_service.sh

clean:
	rm -rf $(web_static_path)/*png
