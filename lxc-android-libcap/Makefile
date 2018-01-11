#
# Makefile for libcap
#
topdir=$(shell pwd)
include Make.Rules

#
# flags
#

all install clean: %: %-here
	$(MAKE) -C libcap $@
ifneq ($(PAM_CAP),no)
	$(MAKE) -C pam_cap $@
endif
	$(MAKE) -C progs $@
	$(MAKE) -C doc $@

all-here:

install-here:

clean-here:
	$(LOCALCLEAN)

distclean: clean
	$(DISTCLEAN)

release: distclean
	cd .. && ln -s libcap libcap-$(VERSION).$(MINOR) && tar cvfz libcap-$(VERSION).$(MINOR).tar.gz libcap-$(VERSION).$(MINOR)/* && rm libcap-$(VERSION).$(MINOR)

tagrelease: distclean
	git tag -s libcap-$(VERSION).$(MINOR)
	make release
