#!/usr/bin/make -rsf

.SUFFIXES:

SRC	:=$(PWD)
TMP:=/tmp
BUILD_ROOT:=$(PWD)/TEKII_BUILD
VENDOR:=$(PWD)/VENDOR

#
# M4
#
M4:=$(shell which m4)
M4_FLAGS:= -I $(SRC)
M4_FLAGS+= \
	-I /usr/share/autoconf \
	-R /usr/share/autoconf/m4sugar/m4sugar.m4f \
	-D __REALPATH__=$(shell which realpath) \
	-D __SRC__=$(SRC)

ifdef PREVIEW
M4_FLAGS+= -D __PREVIEW__
endif

#
# BUILD MODE STAMP
#
# build and preview now share one BUILD_ROOT (TEKII_BUILD), differing only in
# __PREVIEW__'s effect on generated HTML (relative vs absolute URLs -- see
# __ABSOLUTE in generator.m4). Make's mtime-based staleness has no way to
# notice that switch on its own: a `make build` immediately followed by
# `make preview` touches no source file, so without this stamp the stale
# absolute-URL HTML from the prior run would survive untouched.
#
# MODE_STAMP records the last mode a run actually used. Comparing it against
# the mode this invocation wants runs at parse time, before any rule is
# considered; if they differ, the stamp file's mtime is bumped to "now". The
# per-page .html rule (generator.m4) lists MODE_STAMP as a real prerequisite,
# so a bumped stamp makes Make treat that one rule -- and only that rule, the
# one whose output actually depends on __PREVIEW__ -- as stale and rebuild it.
# Skipped for clean/realclean: those don't read BUILD_ROOT's contents, and
# realclean removes the stamp along with everything else under TEKII_BUILD.
# Also skipped for the bare `preview` goal itself: it's only a recursive
# trampoline (`preview: ; $(MAKE) PREVIEW=1`, below) with no PREVIEW of its
# own, so its outer invocation would otherwise compute MODE=build and stamp
# that, immediately before the inner PREVIEW=1 invocation stamps "preview"
# back -- two spurious writes, every call, regardless of whether the mode
# actually changed. Only the inner invocation (MAKECMDGOALS is empty there;
# the recursive call passes no goal, just PREVIEW=1) should decide MODE.
ifeq ($(filter clean% realclean preview,$(MAKECMDGOALS)),)
MODE:=$(if $(PREVIEW),preview,build)
MODE_STAMP:=$(BUILD_ROOT)/.mode
ifneq ($(MODE),$(shell cat $(MODE_STAMP) 2>/dev/null))
$(shell mkdir -p $(BUILD_ROOT) && echo $(MODE) > $(MODE_STAMP))
endif
endif

#
# RULES START HERE
#
# .SECONDEXPANSION enables $$(@D)/ in prerequisites — Make expands $$ a second
# time after automatic variables are set, so $$(@D)/ resolves to the target's dir.
.SECONDEXPANSION:

#
# CREATE DIR ON DEMAND
#
.PRECIOUS: $(PWD)/%/
$(PWD)/%/:
	mkdir -p $@

.PRECIOUS: $(TMP)/%/
$(TMP)/%/:
	mkdir -p $@

#
# VENDOR
#
.PHONY: vendor
vendor:

#
# NAVIGATION MAP
#
define do-generate-navigation
	$(M4) -D __PHASE__=GENERATE_NAVIGATION_PHASE $(M4_FLAGS) \
	-D __BUILD_ROOT__=$(BUILD_ROOT) \
	$(EXTRA_NAV_FLAGS) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 > $@
endef

define do-generate-landing
	$(M4) -D __PHASE__=GENERATE_LANDING_PHASE $(M4_FLAGS) \
	-D __BUILD_ROOT__=$(BUILD_ROOT) \
	$(EXTRA_LANDING_FLAGS) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 > $@
endef

$(BUILD_ROOT)/NAV/%/NAVIGATION.m4 : | $$(@D)/
	sort -u $^ | grep -v '^$$' > $@

# DOC-level aggregate of just the domains' landing pages (one stem-fragment
# per domain that opted in via __MAKE_PAGE([LinkType],[landing])), so any
# page can cross-link to another domain's landing page.
$(BUILD_ROOT)/NAV/NAVIGATION-LANDING.m4 : | $$(@D)/
	cat $^ > $@

define do-generate-html
$(M4) -D __PHASE__=GENERATE_HTML_PHASE $(M4_FLAGS) \
	-D __BUILD_ROOT__=$(BUILD_ROOT) \
	$(EXTRA_HTML_FLAGS) \
	-D __TDIR__=$(@D) -D __TNAME__=$(@F) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 >$@
endef

define do-generate-deferred-mk
$(M4) -D __PHASE__=GENERATE_DEFERRED_MK_PHASE $(M4_FLAGS) \
	-D __BUILD_ROOT__=$(BUILD_ROOT) \
	$(EXTRA_DEFERRED_MK_FLAGS) \
	-D __TDIR__=$(@D) -D __TNAME__=$(@F) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 >$@ || rm $@
endef


#
# GZIPED TARGETS
#
# reset to empty; per-target rules set this to add -h "Cache-Control:..." etc.
GSUTIL_EXTRA_FLAGS:=

define do-compress
	gzip -c --no-name --rsyncable $< >$@
endef

# no explicit prerequisites: the -include'd DEP/*.mk files wire all real deps.
.PHONY: build
build:
	@echo [[[ DONE $@ ]]]

# convenience alias: make PREVIEW=1 is the canonical form
.PHONY: preview
preview:
	$(MAKE) PREVIEW=1

define do-publish
	@echo "++++++ gsutil $(GSUTIL_EXTRA_FLAGS) -h "Content-Encoding:gzip" cp -a public-read -r $<  gs://$@"
	@echo [[[ PUBLISHED $@ ]]]
endef

.PHONY: publish
publish: #$(ALL_GZIP)
	@echo [[[ DONE $@ ]]]

.PHONY: all
all: build

# clean-* base rules: double-colon so generated .mk files can append recipes.
.PHONY: build-clean assets-clean compressed-files-clean makefiles-clean navigation-files-clean
build-clean ::
assets-clean ::
compressed-files-clean ::
makefiles-clean ::
navigation-files-clean ::

.PHONY: clean
clean : build-clean assets-clean compressed-files-clean makefiles-clean navigation-files-clean
	@echo [[[ DONE $@ ]]]

.PHONY: realclean
realclean:: clean
	@rm -rf TEKII_BUILD
	@echo [[[ DONE $@ ]]]


#
# WITH_XXX MACRO TESTS
#
.PHONY: test-with-xxx-macros
test-with-xxx-macros:
	@for phase in GENERATE_MAKEFILE_PHASE GENERATE_NAVIGATION_PHASE GENERATE_LANDING_PHASE; do \
		ext=$$(echo $$phase | tr A-Z a-z) ; \
		$(M4) -D __PHASE__=$$phase $(M4_FLAGS) \
			-D __STEM__=mock-page \
			-D __BUILD_ROOT__=$(BUILD_ROOT) \
			-D __VENDOR__=$(SRC)/tests/fixtures/MOCK_VENDOR \
			-D __TARGET__=MOCK_TARGET.mk \
			-D __FIRST__=$(SRC)/tests/fixtures/mock-page.in.html \
			generator.m4 \
			| sed 's,$(SRC),@SRC@,g' > $(TMP)/mock-page.$$ext ; \
		diff -u $(SRC)/tests/golden/mock-page.$$ext $(TMP)/mock-page.$$ext || exit 1 ; \
	done
	@echo "test-with-xxx-macros: PASS"

#
# COMMANDS --debug=aeqt
#
.PHONY: test
test: test-with-xxx-macros
test: EXTRA_BUILD_FLAGS= -D __DOMAIN__:=http://tests.com -D __LAYOUT__=$(SRC)/empty.txt
test: generator_test.m4
	$(M4) $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) \
	-D __BUILD_ROOT__=$(BUILD_ROOT) \
	--debug= \
	-D __PHASE__=TEST_PHASE \
	-D __TDIR__="$(TMP)/test" \
	-D __TARGET__=$(TMP)/test/dummy -D __FIRST__=$(SRC)/empty.txt \
	generator_test.m4 > $(TMP)/generator_test.out
	@cat $(TMP)/generator_test.out
	@! grep -q '^FAIL' $(TMP)/generator_test.out

# suppress errors: files may already be absent, which is expected during clean.
.IGNORE: clean compressed-files-clean realclean
.DEFAULT_GOAL := build

#
# __BUILD_ROOT__ is intentionally absent: GENERATE_MAKEFILE_PHASE emits [$(BUILD_ROOT)]/...
# so generated .mk files carry Make variable references, not literal paths.
#
ifeq ($(filter clean% realclean,$(MAKECMDGOALS)),)
$(BUILD_ROOT)/DEP/%.mk: $(SRC)/%.in.html $(SRC)/generator.m4 Makefile | $$(@D)/
	$(M4) -D __PHASE__=GENERATE_MAKEFILE_PHASE $(M4_FLAGS) \
		-D __STEM__=$* \
		-D __VENDOR__=$(VENDOR) \
		-D __TARGET__=$@ -D __FIRST__=$< \
		generator.m4 >$@ || rm $@
endif

# triggers the DEP pattern rule above for any stem missing its .mk
-include $(patsubst %.in.html,$(BUILD_ROOT)/DEP/%.mk,$(notdir $(wildcard $(SRC)/*.in.html)))

