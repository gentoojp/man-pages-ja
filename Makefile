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

define pod2man
  @addendum=$(subst $(builddir)/,$(podir)/,$@).txt; \
  if [ ! -f $$addendum ]; then \
    addendum=/dev/null; \
  fi; \
  echo "cat $$addendum > $@"; \
  cat $$addendum > $@
  pod2man --stderr --utf8 $(PODFLAGS) $< >> $@
endef

define po4a
  po4a \
    --no-backups \
    --variable srcdir=$(srcdir)/$(1) \
    --variable builddir=$(builddir)/$(1) \
    --variable podir=$(podir)/$(1) \
    --package-name $($(subst -,_,$(1))_NAME) \
    --package-version $($(subst -,_,$(1))_VERSION) \
    $(POFLAGS) \
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

portage_NAME    := Portage
portage_VERSION := 2.0.51-r3
portage_DATE    := 2004-11-05
portage_SOURCES := portage/dispatch-conf.1 \
                   portage/dispatch-conf.1.ja.po \
                   portage/dispatch-conf.1.txt \
                   portage/ebuild.1 \
                   portage/ebuild.1.ja.po \
                   portage/ebuild.1.txt \
                   portage/emerge.1 \
                   portage/emerge.1.ja.po \
                   portage/emerge.1.txt \
                   portage/env-update.1 \
                   portage/env-update.1.ja.po \
                   portage/env-update.1.txt \
                   portage/etc-update.1 \
                   portage/etc-update.1.ja.po \
                   portage/etc-update.1.txt \
                   portage/g-cpan.pl.1 \
                   portage/g-cpan.pl.1.ja.po \
                   portage/g-cpan.pl.1.txt \
                   portage/quickpkg.1 \
                   portage/quickpkg.1.ja.po \
                   portage/quickpkg.1.txt \
                   portage/repoman.1 \
                   portage/repoman.1.ja.po \
                   portage/repoman.1.txt \
                   portage/check-kernel.eclass.5 \
                   portage/check-kernel.eclass.5.ja.po \
                   portage/check-kernel.eclass.5.txt \
                   portage/cvs.eclass.5 \
                   portage/cvs.eclass.5.ja.po \
                   portage/cvs.eclass.5.txt \
                   portage/distutils.eclass.5 \
                   portage/distutils.eclass.5.ja.po \
                   portage/distutils.eclass.5.txt \
                   portage/ebook.eclass.5 \
                   portage/ebook.eclass.5.ja.po \
                   portage/ebook.eclass.5.txt \
                   portage/ebuild.5 \
                   portage/ebuild.5.ja.po \
                   portage/ebuild.5.txt \
                   portage/eutils.eclass.5 \
                   portage/eutils.eclass.5.ja.po \
                   portage/eutils.eclass.5.txt \
                   portage/flag-o-matic.eclass.5 \
                   portage/flag-o-matic.eclass.5.ja.po \
                   portage/flag-o-matic.eclass.5.txt \
                   portage/font.eclass.5 \
                   portage/font.eclass.5.ja.po \
                   portage/font.eclass.5.txt \
                   portage/games.eclass.5 \
                   portage/games.eclass.5.ja.po \
                   portage/games.eclass.5.txt \
                   portage/horde.eclass.5 \
                   portage/horde.eclass.5.ja.po \
                   portage/horde.eclass.5.txt \
                   portage/libtool.eclass.5 \
                   portage/libtool.eclass.5.ja.po \
                   portage/libtool.eclass.5.txt \
                   portage/make.conf.5 \
                   portage/make.conf.5.ja.po \
                   portage/make.conf.5.txt \
                   portage/perl-module.eclass.5 \
                   portage/perl-module.eclass.5.ja.po \
                   portage/perl-module.eclass.5.txt \
                   portage/portage.5 \
                   portage/portage.5.ja.po \
                   portage/portage.5.txt \
                   portage/rpm.eclass.5 \
                   portage/rpm.eclass.5.ja.po \
                   portage/rpm.eclass.5.txt \
                   portage/ssl-cert.eclass.5 \
                   portage/ssl-cert.eclass.5.ja.po \
                   portage/ssl-cert.eclass.5.txt \
                   portage/stardict.eclass.5 \
                   portage/stardict.eclass.5.ja.po \
                   portage/stardict.eclass.5.txt \
                   portage/toolchain-funcs.eclass.5 \
                   portage/toolchain-funcs.eclass.5.ja.po \
                   portage/toolchain-funcs.eclass.5.txt \
                   portage/vim.eclass.5 \
                   portage/vim.eclass.5.ja.po \
                   portage/vim.eclass.5.txt \
                   portage/portage.cfg
portage_MANS    := $(addprefix $(builddir)/,$(filter %.1 %.5,$(portage_SOURCES)))


.PHONY: all clean pod epm esearch gentoolkit gentoolkit-dev portage
.SUFFIXES:
.SECONDEXPANSION:

%.1: %.pod
	$(call pod2man)

all: epm esearch gentoolkit gentoolkit-dev portage

clean:
	rm -rf $(builddir)
	rm -f  $(podir)/*/*.pot
	rm -f  .*.po4a-stamp

pod: override P := $(subst -,_,$(P))
pod: PODFLAGS   := --center=$($(P)_NAME) --date=$($(P)_DATE) --release="$($(P)_NAME) $($(P)_VERSION)"
pod: $$($$(P)_MANS)

epm:
	$(MAKE) P=$@ pod
$(epm_MANS): $(epm_PODS)
$(epm_PODS): .epm.po4a-stamp
.epm.po4a-stamp: $(epm_SOURCES)
	$(call po4a,epm)
	touch $@

esearch: $(esearch_MANS)
$(esearch_MANS): .esearch.po4a-stamp
.esearch.po4a-stamp: $(esearch_SOURCES)
	$(call po4a,esearch)
	touch $@

gentoolkit: $(gentoolkit_MANS)
$(gentoolkit_MANS): .gentoolkit.po4a-stamp
.gentoolkit.po4a-stamp: $(gentoolkit_SOURCES)
	$(call po4a,gentoolkit)
	touch $@

gentoolkit-dev:
	$(MAKE) P=$@ pod
$(gentoolkit_dev_MANS): $(gentoolkit_dev_PODS)
$(gentoolkit_dev_PODS): .gentoolkit-dev.po4a-stamp
.gentoolkit-dev.po4a-stamp: $(gentoolkit_dev_SOURCES)
	$(call po4a,gentoolkit-dev)
	touch $@

portage: $(portage_MANS)
$(portage_MANS): .portage.po4a-stamp
.portage.po4a-stamp: $(portage_SOURCES)
	$(call po4a,portage)
	touch $@
