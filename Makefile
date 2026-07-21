#!/usr/bin/make -rsf

.SUFFIXES:

SRC	:=$(PWD)
TMP:=/tmp
BUILD_ROOT:=$(PWD)/TEPPAN_BUILD
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
# BUILD MODE STAMP
#
# build and preview now share one BUILD_ROOT (TEPPAN_BUILD), differing only in
# __PREVIEW__'s effect on generated HTML (relative vs absolute URLs -- see
# __ABSOLUTE in generator.m4). Make's mtime-based staleness has no way to
# notice that switch on its own: a `make build` immediately followed by
# `make preview` touches no source file, so without this stamp the stale
# absolute-URL HTML from the prior run would survive untouched.
#
# $(BUILD_ROOT)/.mode-<domain> (one stamp per domain, e.g. .mode-tekii.ar)
# records the last mode a run actually used for that domain. The per-page
# .html rule (generator.m4) lists its own domain's stamp as a real
# prerequisite, so a bumped stamp makes Make treat that domain's pages --
# and only that domain's, the one whose output actually depends on
# __PREVIEW__ -- as stale and rebuild them. Per-domain (not one global
# stamp) so a scoped build/preview of a single domain (e.g. `make PREVIEW=1
# tekii-ar-build`) doesn't force every *other* domain to rebuild on the next
# `build`/`preview` just because the recorded mode no longer matches --
# only the domain that actually changed mode pays that cost.
#
# This is a normal rule, not a parse-time $(shell ...) side effect: each
# stamp depends on the always-out-of-date FORCE (.PHONY, no recipe), so Make
# always reconsiders the stamp's own recipe -- which only rewrites the file
# when the recorded mode differs from this run's MODE. The recipe must be
# the stamp's own (not a same-effect write from a separate companion
# target): Make only re-stats a file after running *that file's* recipe, so
# a write performed as a side effect of some other target's recipe would
# leave Make comparing against a stale cached mtime for the rest of this
# same run (confirmed via `make -d`: a 1-rule-removed-from-its-own-recipe
# version stamped the file correctly on disk but still judged that run's
# .html up to date -- it only rebuilt on the *next* invocation, a one-run
# lag).
# Make only walks into this rule when something reachable from the requested
# goal lists a stamp as a prerequisite, which is true for `build` (via the
# per-page .html rule) but not for `clean`, `realclean`, or the bare
# `preview` trampoline (`preview: ; $(MAKE) PREVIEW=1`, below) -- none of
# those reach the .html rule in their own prerequisite graph, so none of
# them spuriously read or rewrite any stamp.
# Directory creation reuses the project's order-only "%/ on demand" pattern
# above instead of an explicit mkdir.
MODE:=$(if $(PREVIEW),preview,build)
.PHONY: FORCE
FORCE:
$(BUILD_ROOT)/.mode-% : FORCE | $(BUILD_ROOT)/
	@test "$$(cat $@ 2>/dev/null)" = "$(MODE)" || echo $(MODE) > $@

#
# VENDOR
#
# `pico.classless.css` and the 'Days One' brand font (`days-one-latin.woff2`)
# are committed under `third_party/` (tracked source assets delivered via
# __DASSET, like custom.css) so builds are fully offline -- the npm registry is
# reachable in-container but CDNs are firewalled. `vendor` is only an optional
# REFRESH helper to bump the pinned copies; it is NOT a build prerequisite.
# Pins + integrity:
#   @picocss/pico@2.1.1  css/pico.classless.css
#     sha256 76994d55389adc669e0d975a31e33041e81fde36d7d56ad912f3731b222cbdfb
#   @fontsource/days-one@5.2.7  files/days-one-latin-400-normal.woff2 (OFL-1.1)
#     sha256 185dc6bea2e5918892d7f057dc2caa49bbb6e05706176c2b8f387f13f8e2a890
#   googlefonts/noto-emoji @ v2.051  third_party/region-flags/svg/{AR,US,BR}.svg
#     + third_party/region-flags/LICENSE (public-domain/exempt) -- flat region
#     flags, decorative garnish beside the language-switch text names. sha256:
#       region-flag-AR.svg     dafb5bc6543c59249be9c7dec2298eaeaa1fe7805a62754990315cc6db93b2f3
#       region-flag-US.svg     6ca529bf919d51857659fe703c3e4e6e33f7836aa66e62a8ad593209b0be1abf
#       region-flag-BR.svg     6379aeeb756c0b62f4d676e74821b6e4a97652f51fc690ede2a77c7dd48c96e5
#       region-flags.LICENSE   73af5be6e2ea006b75bebfd2f463f252c5ce8c94024c639dbdd97f0456272a5a
# Unlike the npm packs, the region-flags fetch uses curl against
# raw.githubusercontent.com tag URLs -- that host is firewalled in-container, so
# that step of the refresh likely must run host-side (vendor is an optional
# refresh helper, never a build prerequisite; the tracked copies build offline).
# Two npm packs extract into separate subdirs -- both tarballs use a top-level
# `package/`, so a shared extract dir would clobber the first with the second.
.PHONY: vendor
vendor:
	@tmp=$$(mktemp -d) \
	  && ( cd "$$tmp" && npm pack @picocss/pico@2.1.1 >/dev/null && mkdir pico && tar xzf picocss-pico-2.1.1.tgz -C pico ) \
	  && ( cd "$$tmp" && npm pack @fontsource/days-one@5.2.7 >/dev/null && mkdir font && tar xzf fontsource-days-one-5.2.7.tgz -C font ) \
	  && cp "$$tmp/pico/package/css/pico.classless.css" $(SRC)/third_party/pico.classless.css \
	  && cp "$$tmp/pico/package/LICENSE.md" $(SRC)/third_party/pico.classless.css.LICENSE \
	  && cp "$$tmp/font/package/files/days-one-latin-400-normal.woff2" $(SRC)/third_party/days-one-latin.woff2 \
	  && cp "$$tmp/font/package/LICENSE" $(SRC)/third_party/days-one-latin.woff2.LICENSE \
	  && rm -rf "$$tmp" \
	  && echo "refreshed pico     -> sha256 $$(sha256sum $(SRC)/third_party/pico.classless.css | cut -d' ' -f1)" \
	  && echo "refreshed days-one -> sha256 $$(sha256sum $(SRC)/third_party/days-one-latin.woff2 | cut -d' ' -f1)"
	@echo "fetching region-flags from googlefonts/noto-emoji@v2.051 (raw.githubusercontent -- runs host-side; firewalled in-container)" \
	  && for f in AR US BR; do curl -fL -o $(SRC)/third_party/region-flag-$$f.svg https://raw.githubusercontent.com/googlefonts/noto-emoji/v2.051/third_party/region-flags/svg/$$f.svg; done \
	  && curl -fL -o $(SRC)/third_party/region-flags.LICENSE https://raw.githubusercontent.com/googlefonts/noto-emoji/v2.051/third_party/region-flags/LICENSE \
	  && for f in AR US BR; do echo "refreshed region-flag-$$f -> sha256 $$(sha256sum $(SRC)/third_party/region-flag-$$f.svg | cut -d' ' -f1)"; done

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

# dedup the per-stem nav fragments while PRESERVING their original order:
# awk '!seen[$0]++' keeps each distinct line's first occurrence (unlike
# `sort -u`, which also reordered the m4_set_add lines and made the nav menu
# alphabetical by label). $$0 is awk's $0 escaped for Make.
$(BUILD_ROOT)/NAV/%/NAVIGATION.m4 : | $$(@D)/
	awk '!seen[$$0]++' $^ | grep -v '^$$' > $@

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
	@rm -rf TEPPAN_BUILD
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

