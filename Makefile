.PHONY: build install uninstall clean release

PREFIX ?= /usr/local

build:
	swift build

release:
	swift build -c release

install: release
	install -d $(PREFIX)/bin
	install .build/release/calbuddy $(PREFIX)/bin/calbuddy

uninstall:
	rm -f $(PREFIX)/bin/calbuddy

clean:
	swift package clean
	rm -rf .build
