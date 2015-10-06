DESTDIR := /usr/local
DEPENDENCIES=Commander PathKit
LIBS=$(addprefix lib, $(DEPENDENCIES))
SWIFTFLAGS=$(addprefix -l, $(DEPENDENCIES))

build: libConche
	@echo "Building bin/conche"
	@swiftc -I .conche/modules -L .conche/lib $(SWIFTFLAGS) -lConche -o bin/conche bin/conche.swift

clean:
	rm -fr .conche/modules .conche/lib

libConche: $(LIBS)
	@echo "Building Conche"
	@swiftc $(SWIFTFLAGS) -I .conche/modules -L .conche/lib -module-name Conche -emit-library -emit-module -emit-module-path .conche/modules/Conche.swiftmodule Conche/*.swift -o .conche/lib/libConche.dylib

lib%:
	@mkdir -p .conche/modules
	@mkdir -p .conche/lib
	@echo "Building $*"
	@swiftc -module-name $* -emit-library -emit-module -emit-module-path .conche/modules/$*.swiftmodule .conche/packages/$*/$*/*.swift -o .conche/lib/lib$*.dylib

install: build
	mkdir -p "$(DESTDIR)/bin/"
	mkdir -p "$(DESTDIR)/lib/"
	cp -f "bin/conche" "$(DESTDIR)/bin/"
	cp -fr ".conche/lib/" "$(DESTDIR)/lib/"

