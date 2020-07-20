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

HEADERS  = 	AddressSpace.hpp 		\
			CompactUnwinder.hpp 	\
			DwarfInstructions.hpp 	\
			DwarfParser.hpp 		\
			FileAbstraction.hpp		\
			InternalMacros.h 		\
			Registers.hpp			\
			UnwindCursor.hpp		\
			libunwind_priv.h 		\
			dwarf2.h

SRCS = 	  	Unwind-sjlj.c \
			UnwindLevel1-gcc-ext.c \
			UnwindLevel1.c \
			libuwind.cxx \
			unw_getcontext.s \
			Registers.s


# Building

all: libosxunwind.a libosxunwind.dylib

override SRCS := $(addprefix src/,$(SRCS))
override HEADERS := $(addprefix src/,$(HEADERS))

OBJS = 	$(patsubst %.c,%.c.o,			\
		$(patsubst %.s,%.s.o,			\
		$(patsubst %.cxx,%.cxx.o,$(SRCS))))

%.c.o: %.c
	$(CC) $(CPPFLAGS_add) $(CPPFLAGS) $(CFLAGS_add) $(CFLAGS) -c $< -o $@

%.cxx.o: %.cxx
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
.SUFFIXES: .cxx
