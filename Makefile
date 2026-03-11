.PHONY: build install uninstall clean release version

PREFIX ?= /usr/local
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "unknown")

version:
	echo 'public let calbuddyVersion = "$(VERSION)"' > Sources/CalBuddyLib/Version.swift

build: version
	swift build

release: version
	swift build -c release --disable-sandbox

install: release
	install -d $(PREFIX)/bin
	install .build/release/calbuddy $(PREFIX)/bin/calbuddy

uninstall:
	rm -f $(PREFIX)/bin/calbuddy

clean:
	swift package clean
	rm -rf .build
