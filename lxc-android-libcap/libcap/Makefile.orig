#
# defines
#
topdir=$(shell pwd)/..
include ../Make.Rules
#
# Library version
#
LIBNAME=$(LIBTITLE).so
STALIBNAME=$(LIBTITLE).a
#

FILES=cap_alloc cap_proc cap_extint cap_flag cap_text

# make including file support something you can override (no libattr
# no support).
ifeq ($(LIBATTR),yes)
FILES += cap_file
LDFLAGS += -lattr
endif

INCLS=libcap.h cap_names.h $(INCS)
OBJS=$(addsuffix .o, $(FILES))
MAJLIBNAME=$(LIBNAME).$(VERSION)
MINLIBNAME=$(MAJLIBNAME).$(MINOR)
GPERF_OUTPUT = _caps_output.gperf

all: $(MINLIBNAME) $(STALIBNAME)

ifeq ($(shell gperf --version > /dev/null 2>&1 && echo yes),yes)
USE_GPERF_OUTPUT = $(GPERF_OUTPUT)
INCLUDE_GPERF_OUTPUT = -include $(GPERF_OUTPUT)
endif

_makenames: _makenames.c cap_names.list.h
	$(BUILD_CC) $(BUILD_CFLAGS) $< -o $@

cap_names.h: _makenames
	./_makenames > cap_names.h

$(GPERF_OUTPUT): cap_names.list.h
	perl -e 'print "struct __cap_token_s { const char *name; int index; };\n%{\nconst struct __cap_token_s *__cap_lookup_name(const char *, unsigned int);\n%}\n%%\n"; while ($$l = <>) { $$l =~ s/[\{\"]//g; $$l =~ s/\}.*// ; print $$l; }' < $< | gperf --ignore-case --language=ANSI-C --readonly --null-strings --global-table --hash-function-name=__cap_hash_name --lookup-function-name="__cap_lookup_name" -c -t -m20 $(INDENT) > $@

cap_names.list.h: Makefile $(KERNEL_HEADERS)/linux/capability.h
	@echo "=> making $@ from $(KERNEL_HEADERS)/linux/capability.h"
	perl -e 'while ($$l=<>) { if ($$l =~ /^\#define[ \t](CAP[_A-Z]+)[ \t]+([0-9]+)\s+$$/) { $$tok=$$1; $$val=$$2; $$tok =~ tr/A-Z/a-z/; print "{\"$$tok\",$$val},\n"; } }' $(KERNEL_HEADERS)/linux/capability.h | fgrep -v 0x > $@

$(STALIBNAME): $(OBJS)
	$(AR) rcs $@ $^
	$(RANLIB) $@

$(MINLIBNAME): $(OBJS)
	$(LD) $(CFLAGS) $(LDFLAGS) -Wl,-soname,$(MAJLIBNAME) -o $@ $^
	ln -sf $(MINLIBNAME) $(MAJLIBNAME)
	ln -sf $(MAJLIBNAME) $(LIBNAME)

%.o: %.c $(INCLS)
	$(CC) $(CFLAGS) $(IPATH) -c $< -o $@

cap_text.o: cap_text.c $(USE_GPERF_OUTPUT) $(INCLS)
	$(CC) $(CFLAGS) $(IPATH) $(INCLUDE_GPERF_OUTPUT) -c $< -o $@

install: all
	mkdir -p -m 0755 $(INCDIR)/sys
	install -m 0644 include/sys/capability.h $(INCDIR)/sys
	mkdir -p -m 0755 $(LIBDIR)
	install -m 0644 $(STALIBNAME) $(LIBDIR)/$(STALIBNAME)
	install -m 0644 $(MINLIBNAME) $(LIBDIR)/$(MINLIBNAME)
	ln -sf $(MINLIBNAME) $(LIBDIR)/$(MAJLIBNAME)
	ln -sf $(MAJLIBNAME) $(LIBDIR)/$(LIBNAME)
ifeq ($(FAKEROOT),)
	-/sbin/ldconfig
endif

clean:
	$(LOCALCLEAN)
	rm -f $(OBJS) $(LIBNAME)* $(STALIBNAME)
	rm -f cap_names.h cap_names.list.h _makenames $(GPERF_OUTPUT)
	cd include/sys && $(LOCALCLEAN)
