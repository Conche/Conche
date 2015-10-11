DESTDIR := /usr/local
DEPENDENCIES = Commander PathKit
LIBS = $(foreach lib,$(DEPENDENCIES),.conche/lib/lib$(lib).dylib)
SWIFTC := swiftc
SWIFTFLAGS = $(addprefix -l, $(DEPENDENCIES))

SOURCES = Dependency DependencyResolver Downloader Source Specification build test
SOURCE_FILES = $(foreach file,$(SOURCES),Conche/$(file).swift)


all: bin/conche

bin/conche: .conche/lib/libConche.dylib bin/conche.swift
	@echo "Building bin/conche"
	@$(SWIFTC) -I .conche/modules -L .conche/lib $(SWIFTFLAGS) -lConche -o bin/conche bin/conche.swift

clean:
	rm -fr .conche/modules .conche/lib

.conche/lib/libConche.dylib: $(LIBS) $(SOURCE_FILES)
	@echo "Building Conche"
	@$(SWIFTC) $(SWIFTFLAGS) -I .conche/modules -L .conche/lib -module-name Conche -emit-library -emit-module -emit-module-path .conche/modules/Conche.swiftmodule $(SOURCE_FILES) -o .conche/lib/libConche.dylib

.conche/lib/lib%.dylib:
	@mkdir -p .conche/modules
	@mkdir -p .conche/lib
	@echo "Building $*"
	@$(SWIFTC) -module-name $* -emit-library -emit-module -emit-module-path .conche/modules/$*.swiftmodule .conche/packages/$*/$*/*.swift -o .conche/lib/lib$*.dylib

test: bin/conche
	@./bin/conche test

install: bin/conche
	mkdir -p "$(DESTDIR)/bin/"
	mkdir -p "$(DESTDIR)/lib/"
	cp -f "bin/conche" "$(DESTDIR)/bin/"
	cp -fr ".conche/lib/" "$(DESTDIR)/lib/"

