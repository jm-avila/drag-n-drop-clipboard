.PHONY: build test app run-app clean

build:
	swift build

test:
	swift run ShelfletCoreProbe

app:
	swift build -c release
	rm -rf .build/Shelflet.app
	mkdir -p .build/Shelflet.app/Contents/MacOS
	cp .build/release/Shelflet .build/Shelflet.app/Contents/MacOS/Shelflet
	cp Packaging/Info.plist .build/Shelflet.app/Contents/Info.plist
	chmod +x .build/Shelflet.app/Contents/MacOS/Shelflet

run-app: app
	open .build/Shelflet.app

clean:
	rm -rf .build/Shelflet.app
	swift package clean
