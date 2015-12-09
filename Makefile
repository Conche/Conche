DESTDIR := /usr/local
DEPENDENCIES = Commander PathKit
ifeq ($(UNAME), Darwin)
LIBEXT=dylib
SWIFTC := xcrun -sdk macosx swiftc
else
SWIFTC := swiftc
LIBEXT=so
endif
SWIFTFLAGS = $(addprefix -l, $(DEPENDENCIES))
LIBS = $(foreach lib,$(DEPENDENCIES),.conche/lib/lib$(lib).$(LIBEXT))

SOURCES = Dependency DependencyGraph DependencyResolver DependencyResolverError Downloader \
		  Source Specification SpecificationBuilder Invoke Version \
		  Task Tasks/SpecificationTask Tasks/ModuleBuildTask \
		  Commands/build Commands/test Commands/init
SOURCE_FILES = $(foreach file,$(SOURCES),Conche/$(file).swift)


all: .conche/bin/conche

.conche/bin/conche: .conche/lib/libConche.$(LIBEXT) bin/conche.swift
	@echo "Building .conche/bin/conche"
	@mkdir -p .conche/bin
	@$(SWIFTC) -I .conche/modules -L .conche/lib $(SWIFTFLAGS) -lConche -o bin/conche bin/conche.swift

clean:
	rm -fr .conche/bin .conche/modules .conche/lib

.conche/lib/libConche.$(LIBEXT): $(LIBS) $(SOURCE_FILES)
	@echo "Building Conche"
	@$(SWIFTC) $(SWIFTFLAGS) -I .conche/modules -L .conche/lib -module-name Conche -emit-library -emit-module -emit-module-path .conche/modules/Conche.swiftmodule $(SOURCE_FILES) -o .conche/lib/libConche.$(LIBEXT)

.conche/lib/lib%.$(LIBEXT):
	@mkdir -p .conche/modules
	@mkdir -p .conche/lib
	@echo "Building $*"
	@$(SWIFTC) -module-name $* -emit-library -emit-module -emit-module-path .conche/modules/$*.swiftmodule .conche/packages/$*/Sources/*.swift -o .conche/lib/lib$*.$(LIBEXT)

test: .conche/bin/conche .conche/lib/libSpectre.$(LIBEXT)
	@./bin/conche test

install: .conche/bin/conche
	install -d "$(DESTDIR)/bin" "$(DESTDIR)/lib/conche"
	install -C ".conche/bin/conche" "$(DESTDIR)/bin/"
	install -C $(LIBS) ".conche/lib/libConche.dylib" "$(DESTDIR)/lib/conche"
	install_name_tool -change ".conche/lib/libCommander.dylib" "@executable_path/../lib/conche/libCommander.dylib" "$(DESTDIR)/bin/conche"
	install_name_tool -change ".conche/lib/libPathKit.dylib" "@executable_path/../lib/conche/libPathKit.dylib" "$(DESTDIR)/bin/conche"
	install_name_tool -change ".conche/lib/libConche.dylib" "@executable_path/../lib/conche/libConche.dylib" "$(DESTDIR)/bin/conche"
	install_name_tool -change ".conche/lib/libCommander.dylib" "@executable_path/../lib/conche/libCommander.dylib" "$(DESTDIR)/lib/conche/libConche.dylib"
	install_name_tool -change ".conche/lib/libPathKit.dylib" "@executable_path/../lib/conche/libPathKit.dylib" "$(DESTDIR)/lib/conche/libConche.dylib"
