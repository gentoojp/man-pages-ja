#
# Makefile for GentooJP man-pages-ja
#

srcdir   := en
podir    := po
builddir := build

vpath %.po  $(podir)
vpath %.txt $(podir)
vpath %.cfg $(podir)
vpath %     $(srcdir)

POD2MAN := pod2man --stderr --utf8
define po4a
  po4a \
    --no-backups \
    --variable srcdir=$(srcdir)/$(1) \
    --variable builddir=$(builddir)/$(1) \
    --variable podir=$(podir)/$(1) \
    --package-name $($(subst -,_,$(1))_NAME) \
    --package-version $($(subst -,_,$(1))_VERSION) \
    $(podir)/$(1)/$(1).cfg
endef

epm_NAME    := epm
epm_VERSION := 0.8.4
epm_DATE    := 2003-05-27
epm_SOURCES := epm/epm \
               epm/epm.ja.po \
               epm/epm.1.txt \
               epm/epm.cfg
epm_PODS    := $(builddir)/epm/epm.pod
epm_MANS    := $(patsubst %.pod,%.1,$(epm_PODS))


.PHONY: all clean pod epm
.SECONDEXPANSION:

%.1: %.in
	@addendum=$(subst $(builddir)/,$(podir)/,$@).txt; \
	if [ -f $$addendum ]; then \
	  echo "cat $$addendum  >$@"; \
	  cat $$addendum  >$@; \
	fi
	cat $< >>$@

%.in: %.pod
	$(POD2MAN) $(PODFLAGS) $< >$@

all: epm

clean:
	rm -rf $(builddir)
	rm -f  $(podir)/*/*.pot
	rm -f  .*-stamp

pod: override P := $(subst -,_,$(P))
pod: PODFLAGS   := --center=$($(P)_NAME) --date=$($(P)_DATE) --release="$($(P)_NAME) $($(P)_VERSION)"
pod: $$($$(P)_MANS)

epm:
	$(MAKE) P=$@ pod
$(epm_MANS): $(epm_PODS)
$(epm_PODS): .po4a-epm-stamp
.po4a-epm-stamp: $(epm_SOURCES)
	$(call po4a,epm)
	touch $@
