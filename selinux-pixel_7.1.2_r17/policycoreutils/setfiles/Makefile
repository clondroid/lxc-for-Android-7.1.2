#export CROSS_COMPILE = aarch64-linux-android-
#export CC = ${CROSS_COMPILE}gcc
#export AR = ${CROSS_COMPILE}ar
#export RANLIB = ${CROSS_COMPILE}ranlib

export PREFIX = $(ODMDIR)

# Installation directories.
PREFIX ?= $(DESTDIR)/usr
SBINDIR ?= $(PREFIX)/sbin
BINDIR ?= $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man
LIBDIR ?= $(PREFIX)/lib
AUDITH = $(shell ls /usr/include/libaudit.h 2>/dev/null)

PROGRESS_STEP=$(shell grep "^\#define STAR_COUNT" restore.h | awk -S '{ print $$3 }')
ABORT_ON_ERRORS=$(shell grep "^\#define ABORT_ON_ERRORS" setfiles.c | awk -S '{ print $$3 }')

CFLAGS ?= -g -Werror -Wall -W --sysroot=$(SYSROOT) -Wno-sign-compare
override CFLAGS += -I$(PREFIX)/include -fPIE -pie
#LDLIBS = -lselinux -lsepol -L$(LIBDIR) -lpcre -lm -lc++ 
LDLIBS = $(LDFLAGS) -lpcre -lm -lc++ $(DESTDIR)/lib/libselinux.a $(DESTDIR)/lib/libsepol.a

#ifeq ($(AUDITH), /usr/include/libaudit.h)
#	override CFLAGS += -DUSE_AUDIT
#	LDLIBS += -laudit
#endif

#all: setfiles restorecon man
all: setfiles

setfiles:  setfiles.o restore.o glob.o

restorecon: setfiles
	ln -sf setfiles restorecon

man:
	@cp -af setfiles.8 setfiles.8.man
	@cp -af restorecon.8 restorecon.8.man
	@sed -i "s/STAR_COUNT/$(PROGRESS_STEP)/g" setfiles.8.man restorecon.8.man
	@sed -i "s/ABORT_ON_ERRORS/$(ABORT_ON_ERRORS)/g" setfiles.8.man

install: all
#	[ -d $(MANDIR)/man8 ] || mkdir -p $(MANDIR)/man8
#	-mkdir -p $(SBINDIR)
	install -m 755 setfiles $(BINDIR)
#	(cd $(SBINDIR) && ln -sf setfiles restorecon)
#	install -m 644 setfiles.8.man $(MANDIR)/man8/setfiles.8
#	install -m 644 restorecon.8.man $(MANDIR)/man8/restorecon.8

clean:
	rm -f setfiles restorecon *.o setfiles.8.man restorecon.8.man

indent:
	../../scripts/Lindent $(wildcard *.[ch])

relabel: install
	$(SBINDIR)/restorecon $(SBINDIR)/setfiles
