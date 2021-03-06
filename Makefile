#!/usr/bin/make -f

SHELL = /bin/bash
ZED_DIR = /Users/zef/Dropbox/zed
INDEX_COMMAND = find app/config -name '*.*' -not -path '*/.git/*' -not -path '*/.git' | sort | sed 's:^app/config::' > app/config/all
NW_VERSION=v0.9.2
ZED_VERSION=$(shell cat app/manifest.json | grep '"version"' | cut -f 4 -d '"')

app/ace:
	curl -L https://github.com/zefhemel/ace-builds/archive/master.tar.gz | tar xzf -
	rm -rf app/ace
	mv ace-builds-master/ace app/ace
	rm -rf ace-builds-master

copy-packages:
	rm -rf app/config/packages/*
	cp -r $(ZED_DIR)/packages/gh app/config/packages/
	find app/config/packages -name .git -exec rm -rf {} \; || echo

build-package: copy-packages indexes
	rm -f zed.zip
	cd app; zip ../zed.zip -x '*.git*' -r *

package: build-package
	rm -rf app/config/packages/*
	$(INDEX_COMMAND)

index-manual:
	find app/manual -name '*.*' -not -path "*/.git/*" -not -path "*/.git" | sort | sed "s:^app/manual::" > app/manual/all

index-config:
	$(INDEX_COMMAND)

nw/download:
	rm -rf nw/download
	mkdir -p nw/download
	cd nw/download && curl -O http://dl.node-webkit.org/$(NW_VERSION)/node-webkit-$(NW_VERSION)-linux-ia32.tar.gz && tar xzf node-webkit-$(NW_VERSION)-linux-ia32.tar.gz
	cd nw/download && curl -O http://dl.node-webkit.org/$(NW_VERSION)/node-webkit-$(NW_VERSION)-linux-x64.tar.gz && tar xzf node-webkit-$(NW_VERSION)-linux-x64.tar.gz
	cd nw/download && curl -O http://dl.node-webkit.org/$(NW_VERSION)/node-webkit-$(NW_VERSION)-win-ia32.zip && unzip -d node-webkit-$(NW_VERSION)-win-ia32 node-webkit-$(NW_VERSION)-win-ia32.zip
	cd nw/download && curl -O http://dl.node-webkit.org/$(NW_VERSION)/node-webkit-$(NW_VERSION)-osx-ia32.zip && unzip -d node-webkit-$(NW_VERSION)-osx-ia32 node-webkit-$(NW_VERSION)-osx-ia32.zip

apps-npm:
	cd app; npm install

apps-mac: app/ace nw/download apps-npm
	rm -rf nw/build
	mkdir -p nw/build
	cp -r nw/download/node-webkit-$(NW_VERSION)-osx-ia32/node-webkit.app nw/build/Zed.app
	cp nw/nw.icns nw/build/Zed.app/Contents/Resources/nw.icns
	cp nw/Info.plist nw/build/Zed.app/Contents/Info.plist
	cp -r app nw/build/Zed.app/Contents/Resources/app.nw
	mkdir nw/build/Zed.app/bin
	cp nw/zed-mac nw/build/Zed.app/bin/zed
	mkdir -p release
	rm -f release/zed-mac.zip
	cd nw/build; tar czf ../../release/zed-mac-v$(ZED_VERSION).tar.gz Zed.app

app.nw: apps-npm
	mkdir -p release
	rm -f nw/app.nw
	cd app; zip -r ../nw/app.nw *

apps-win: app/ace nw/download app.nw
	rm -rf nw/build
	mkdir -p nw/build/zed
	cat nw/download/node-webkit-$(NW_VERSION)-win-ia32/nw.exe nw/app.nw > nw/build/zed/zed.exe
	cp nw/download/node-webkit-$(NW_VERSION)-win-ia32/{nw.pak,icudt.dll} nw/build/zed/
	rm -f release/zed-win.zip
	rm -f release/zed-win.tar.gz
	cd nw/build; zip -r ../../release/zed-win-v$(ZED_VERSION).zip *
	cd nw/build; tar cvzf ../../release/zed-win-v$(ZED_VERSION).tar.gz *

apps-linux64: app/ace nw/download app.nw
	rm -rf nw/build
	mkdir -p nw/build/zed
	cat nw/download/node-webkit-$(NW_VERSION)-linux-x64/nw nw/app.nw > nw/build/zed/zed-bin
	cp nw/download/node-webkit-$(NW_VERSION)-linux-x64/nw.pak nw/build/zed/
	cp nw/zed-linux nw/build/zed/zed
	chmod +x nw/build/zed/zed*
	rm -f release/zed-linux64.tar.gz
	cd nw/build; tar cvzf ../../release/zed-linux64-v$(ZED_VERSION).tar.gz *

apps-linux32: app/ace nw/download app.nw
	rm -rf nw/build
	mkdir -p nw/build/zed
	cat nw/download/node-webkit-$(NW_VERSION)-linux-ia32/nw nw/app.nw > nw/build/zed/zed-bin
	cp nw/download/node-webkit-$(NW_VERSION)-linux-ia32/nw.pak nw/build/zed/
	cp nw/zed-linux nw/build/zed/zed
	chmod +x nw/build/zed/zed*
	rm -f release/zed-linux32.tar.gz
	cd nw/build; tar cvzf ../../release/zed-linux32-v$(ZED_VERSION).tar.gz *

apps: copy-packages indexes apps-mac apps-win apps-linux32 apps-linux64
	echo $(ZED_VERSION) > release/current-version.txt
	rm -rf app/config/packages/*
	$(INDEX_COMMAND)

indexes: index-manual index-config
	@true
