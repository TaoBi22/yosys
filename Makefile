
CONFIG := clang-debug
# CONFIG := gcc-debug
# CONFIG := release

OBJS  = kernel/driver.o kernel/register.o kernel/rtlil.o kernel/log.o kernel/calc.o kernel/select.o kernel/show.o

OBJS += libs/bigint/BigIntegerAlgorithms.o libs/bigint/BigInteger.o libs/bigint/BigIntegerUtils.o
OBJS += libs/bigint/BigUnsigned.o libs/bigint/BigUnsignedInABase.o

OBJS += libs/sha1/sha1.o
OBJS += libs/subcircuit/subcircuit.o

GENFILES =
TARGETS = yosys yosys-config

all: top-all

CXXFLAGS = -Wall -Wextra -ggdb -I"$(shell pwd)" -MD -D_YOSYS_ -fPIC
LDFLAGS = -rdynamic
LDLIBS = -lstdc++ -lreadline -lm -ldl

-include Makefile.conf

ifeq ($(CONFIG),clang-debug)
CXX = clang
CXXFLAGS += -std=c++11 -O0
endif

ifeq ($(CONFIG),gcc-debug)
CXX = gcc
CXXFLAGS += -std=gnu++0x -O0
endif

ifeq ($(CONFIG),release)
CXX = gcc
CXXFLAGS += -std=gnu++0x -march=native -O3 -DNDEBUG
endif

include frontends/*/Makefile.inc
include passes/*/Makefile.inc
include backends/*/Makefile.inc
include techlibs/Makefile.inc

top-all: $(TARGETS)

yosys: $(OBJS)
	$(CXX) -o yosys $(LDFLAGS) $(OBJS) $(LDLIBS)

yosys-config: yosys-config.in
	sed 's,@CXX@,$(CXX),; s,@CXXFLAGS@,$(CXXFLAGS),; s,@LDFLAGS@,$(LDFLAGS),; s,@LDLIBS@,$(LDLIBS),;' < yosys-config.in > yosys-config
	chmod +x yosys-config

test: yosys
	cd tests/simple && bash run-test.sh
	cd tests/hana && bash run-test.sh
	cd tests/asicworld && bash run-test.sh

install: yosys
	install yosys /usr/local/bin/yosys
	install yosys-config /usr/local/bin/yosys-config

clean:
	rm -f $(OBJS) $(GENFILES) $(TARGETS)
	rm -f libs/*/*.d frontends/*/*.d passes/*/*.d backends/*/*.d kernel/*.d

mrproper: clean
	git clean -xdf

qtcreator:
	{ for file in $(basename $(OBJS)); do \
		for prefix in cc y l; do if [ -f $${file}.$${prefix} ]; then echo $$file.$${prefix}; fi; done \
	done; find backends frontends kernel libs passes -type f \( -name '*.h' -o -name '*.hh' \); } > qtcreator.files
	{ echo .; find backends frontends kernel libs passes -type f \( -name '*.h' -o -name '*.hh' \) -printf '%h\n' | sort -u; } > qtcreator.includes
	touch qtcreator.config qtcreator.creator

config-clean: clean
	rm -f Makefile.conf

config-clang-debug: clean
	echo 'CONFIG := clang-debug' > Makefile.conf

config-gcc-debug: clean
	echo 'CONFIG := gcc-debug' > Makefile.conf

config-release: clean
	echo 'CONFIG := release' > Makefile.conf

-include libs/*/*.d
-include frontends/*/*.d
-include passes/*/*.d
-include backends/*/*.d
-include kernel/*.d

.PHONY: all top-all test clean mrproper qtcreator
.PHONY: config-clean config-clang-debug config-gcc-debug config-release

