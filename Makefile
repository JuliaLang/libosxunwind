LIBOSXUNWIND_HOME = $(abspath .)

# Tools

CC = clang
AR = ar
OBJCONV = objconv

# Flags

CPPFLAGS_add = -Wall -pedantic -I$(LIBOSXUNWIND_HOME)/src -I$(LIBOSXUNWIND_HOME)/include -DNDEBUG
CFLAGS_add = -std=c99 -O3
CXXFLAGS_add = -std=c++11 -O3 -fno-rtti
LDFLAGS_add =
SFLAGS_add = -x assembler-with-cpp

DARWINVER := $(shell uname -r | cut -b 1-2)

# If `-stdlib=` is specified within our environment variables, then don't add another command line argument asking to link against it..
ifeq (,$(findstring -stdlib=,$(CC) $(CPPFLAGS) $(CXXFLAGS)))
DARWINVER_GTE13 := $(shell expr `uname -r | cut -b 1-2` \>= 13)
ifeq ($(DARWINVER_GTE13),1)
CXXFLAGS_add += -stdlib=libc++
LDFLAGS_add += -stdlib=libc++
CPPFLAGS_add += -mmacosx-version-min=10.8
else
LDFLAGS_add += -lstdc++
CPPFLAGS_add += -mmacosx-version-min=10.6
endif
endif

# Files (in src/)

CXXHEADERS = \
			src/AddressSpace.hpp 		\
			src/CompactUnwinder.hpp 	\
			src/DwarfInstructions.hpp 	\
			src/DwarfParser.hpp 		\
			src/FileAbstraction.hpp		\
			src/Registers.hpp			\
			src/UnwindCursor.hpp

HEADERS  = 	src/InternalMacros.h 		\
			src/libunwind_priv.h 		\
			src/dwarf2.h				\
			$(shell find include -name '*.h')

SRCS = 	  	src/Unwind-sjlj.c \
			src/UnwindLevel1-gcc-ext.c \
			src/UnwindLevel1.c \
			src/libuwind.cxx \
			src/unw_getcontext.s \
			src/Registers.s


# Building

all: libosxunwind.a libosxunwind.dylib

OBJS = 	$(patsubst %.c,%.c.o,			\
		$(patsubst %.s,%.s.o,			\
		$(patsubst %.cxx,%.cxx.o,$(SRCS))))

%.c.o: %.c $(HEADERS)
	$(CC) $(CPPFLAGS_add) $(CPPFLAGS) $(CFLAGS_add) $(CFLAGS) -c $< -o $@

%.cxx.o: %.cxx $(HEADERS) $(CXXHEADERS)
	$(CC) $(CPPFLAGS_add) $(CPPFLAGS) $(CXXFLAGS_add) $(CXXFLAGS) -c $< -o $@

%.s.o: %.s
	$(CC) $(SFLAGS_add) $(SFLAGS) $(filter -m% -B% -I% -D%,$(CFLAGS_add)) -c $< -o $@


libosxunwind.a: $(OBJS)  
ifeq (,$(SYMFILE))
	$(AR) -rcs $@ $^
else
	$(AR) -rcs $@.orig $^
	$(OBJCONV) @$(SYMFILE) $@.orig $@
endif

libosxunwind.dylib: libosxunwind.a
	$(CC) -shared $(LDFLAGS_add) -Wl,-all_load $< $(LDFLAGS) -o $@

clean:
	rm -f $(OBJS) *.a *.dylib
distclean: clean

define newline # a literal \n


endef

# Makefile debugging trick:
# call print-VARIABLE to see the runtime value of any variable
# (hardened against any special characters appearing in the output)
print-%:
	@echo '$*=$(subst ','\'',$(subst $(newline),\n,$($*)))'

.SUFFIXES: .cxx
