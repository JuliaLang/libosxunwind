LIBOSXUNWIND_HOME = $(abspath .)

# Tools

CC = clang
AR = ar
OBJCONV = objconv

# Flags

CPPFLAGS_add = -I$(LIBOSXUNWIND_HOME)/src -I$(LIBOSXUNWIND_HOME)/include -DNDEBUG
CFLAGS_add = -std=c99 -Wall -O3
CXXFLAGS_add = -std=c++11 -Wall -O3
LDFLAGS_add = -nodefaultlibs -Wl,-upward-lSystem -Wl,-umbrella,System -lstdc++
SFLAGS_add = -x assembler-with-cpp

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
	$(CC) $(SFLAGS) $(SFLAGS_add) $(filter -m% -B% -I% -D%,$(CFLAGS_add)) -c $< -o $@


libosxunwind.a: $(OBJS)  
ifeq (,$(SYMFILE))
	$(AR) -rcs libosxunwind.a $(OBJS)
else
	$(AR) -rcs libosxunwind.a.orig $(OBJS)
	$(OBJCONV) @$(SYMFILE) libosxunwind.a.orig libosxunwind.a
endif

libosxunwind.dylib: $(OBJS)
	$(CC) -shared $(LDFLAGS_add) libosxunwind.a $(LDFLAGS) -o libosxunwind.dylib

clean:
	rm -f $(OBJS) *.a *.dylib
distclean: clean
	
