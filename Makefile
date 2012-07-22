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

esearch_NAME    := esearch
esearch_VERSION := 0.5.3
esearch_DATE    := 2004-01-11
esearch_SOURCES := esearch/esearch.1 \
                   esearch/esearch.1.ja.po \
                   esearch/esearch.1.txt \
                   esearch/esearch.cfg
esearch_MANS    := $(addprefix $(builddir)/,$(filter %.1,$(esearch_SOURCES)))

gentoolkit_NAME    := gentoolkit
gentoolkit_VERSION := 0.2.1
gentoolkit_DATE    := 2005-12-29
gentoolkit_SOURCES := gentoolkit/eclean.1 \
                      gentoolkit/eclean.1.ja.po \
                      gentoolkit/eclean.1.txt \
                      gentoolkit/equery.1 \
                      gentoolkit/equery.1.ja.po \
                      gentoolkit/equery.1.txt \
                      gentoolkit/euse.1 \
                      gentoolkit/euse.1.ja.po \
                      gentoolkit/euse.1.txt \
                      gentoolkit/glsa-check.1 \
                      gentoolkit/glsa-check.1.ja.po \
                      gentoolkit/glsa-check.1.txt \
                      gentoolkit/revdep-rebuild.1 \
                      gentoolkit/revdep-rebuild.1.ja.po \
                      gentoolkit/revdep-rebuild.1.txt \
                      gentoolkit/gentoolkit.cfg
gentoolkit_MANS    := $(addprefix $(builddir)/,$(filter %.1,$(gentoolkit_SOURCES)))

gentoolkit_dev_NAME    := gentoolkit-dev
gentoolkit_dev_VERSION := 0.2.5
gentoolkit_dev_DATE    := 2005-07-12
gentoolkit_dev_SOURCES := gentoolkit-dev/ebump.1 \
                          gentoolkit-dev/ebump.1.ja.po \
                          gentoolkit-dev/ebump.1.txt \
                          gentoolkit-dev/gensync.1 \
                          gentoolkit-dev/gensync.1.ja.po \
                          gentoolkit-dev/gensync.1.txt \
                          gentoolkit-dev/echangelog.pod \
                          gentoolkit-dev/echangelog.pod.ja.po \
                          gentoolkit-dev/echangelog.1.txt \
                          gentoolkit-dev/ekeyword.pod \
                          gentoolkit-dev/ekeyword.pod.ja.po \
                          gentoolkit-dev/ekeyword.1.txt \
                          gentoolkit-dev/eviewcvs.pod \
                          gentoolkit-dev/eviewcvs.pod.ja.po \
                          gentoolkit-dev/eviewcvs.1.txt \
                          gentoolkit-dev/gentoolkit-dev.cfg
gentoolkit_dev_PODS    := $(addprefix $(builddir)/,$(filter %.pod,$(gentoolkit_dev_SOURCES)))
gentoolkit_dev_MANS    := $(addprefix $(builddir)/,$(filter %.1,$(gentoolkit_dev_SOURCES))) \
                          $(patsubst %.pod,%.1,$(gentoolkit_dev_PODS))


.PHONY: all clean pod epm esearch gentoolkit gentoolkit-dev
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

all: epm esearch gentoolkit gentoolkit-dev

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

esearch: $(esearch_MANS)
$(esearch_MANS): .po4a-esearch-stamp
.po4a-esearch-stamp: $(esearch_SOURCES)
	$(call po4a,esearch)
	touch $@

gentoolkit: $(gentoolkit_MANS)
$(gentoolkit_MANS): .po4a-gentoolkit-stamp
.po4a-gentoolkit-stamp: $(gentoolkit_SOURCES)
	$(call po4a,gentoolkit)
	touch $@

gentoolkit-dev:
	$(MAKE) P=$@ pod
$(gentoolkit_dev_MANS): $(gentoolkit_dev_PODS)
$(gentoolkit_dev_PODS): .po4a-gentoolkit-dev-stamp
.po4a-gentoolkit-dev-stamp: $(gentoolkit_dev_SOURCES)
	$(call po4a,gentoolkit-dev)
	touch $@
