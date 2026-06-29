#!/usr/bin/make -rsf

.SUFFIXES:

__SRC__	:=$(PWD)
__TMP__:=/tmp
__BUILD_ROOT__:=$(PWD)/TEKII_BUILD
__VENDOR__:=$(PWD)/VENDOR
ifdef PREVIEW
__BUILD_ROOT__:=$(PWD)/TEKII_PREVIEW
endif

#
# M4
#
M4:=$(shell which m4)
M4_FLAGS:= -I $(__SRC__)
ifeq ($(shell uname -s),Linux)
M4_FLAGS+= \
	-I /usr/share/autoconf \
	-R /usr/share/autoconf/m4sugar/m4sugar.m4f \
	-D __REALPATH__=$(shell which realpath)
else
M4_FLAGS+= \
	-I /usr/local/Cellar/autoconf/2.69/share/autoconf \
	-R /usr/local/Cellar/autoconf/2.69/share/autoconf/m4sugar/m4sugar.m4f \
	-D __REALPATH__=$(shell which grealpath)
endif
M4_FLAGS+= \
	-D __SRC__=$(__SRC__)
ifdef PREVIEW
M4_FLAGS+= -D __PREVIEW__=1
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

.PRECIOUS: $(__TMP__)/%/
$(__TMP__)/%/:
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
	-D __BUILD_ROOT__=$(__BUILD_ROOT__) \
	$(EXTRA_NAV_FLAGS) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 > $@
endef

define do-generate-landing
	$(M4) -D __PHASE__=GENERATE_LANDING_PHASE $(M4_FLAGS) \
	-D __BUILD_ROOT__=$(__BUILD_ROOT__) \
	$(EXTRA_LANDING_FLAGS) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 > $@
endef

$(__BUILD_ROOT__)/NAV/%/NAVIGATION.m4 : | $$(@D)/
	sort -u $^ | grep -v '^$$' > $@

# DOC-level aggregate of just the domains' landing pages (one stem-fragment
# per domain that opted in via __MAKE_PAGE([LinkType],[landing])), so any
# page can cross-link to another domain's landing page.
$(__BUILD_ROOT__)/NAV/NAVIGATION-LANDING.m4 : | $$(@D)/
	cat $^ > $@

define do-generate-html
$(M4) -D __PHASE__=GENERATE_HTML_PHASE $(M4_FLAGS) \
	-D __BUILD_ROOT__=$(__BUILD_ROOT__) \
	$(EXTRA_HTML_FLAGS) \
	-D __TDIR__=$(@D) -D __TNAME__=$(@F) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 >$@
endef

define do-generate-deferred-mk
$(M4) -D __PHASE__=GENERATE_DEFERRED_MK_PHASE $(M4_FLAGS) \
	-D __BUILD_ROOT__=$(__BUILD_ROOT__) \
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
	@rm -rf TEKII_PREVIEW
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
			-D __BUILD_ROOT__=$(__BUILD_ROOT__) \
			-D __VENDOR__=$(__SRC__)/tests/fixtures/MOCK_VENDOR \
			-D __TARGET__=MOCK_TARGET.mk \
			-D __FIRST__=$(__SRC__)/tests/fixtures/mock-page.in.html \
			generator.m4 \
			| sed 's,$(__SRC__),@SRC@,g' > $(__TMP__)/mock-page.$$ext ; \
		diff -u $(__SRC__)/tests/golden/mock-page.$$ext $(__TMP__)/mock-page.$$ext || exit 1 ; \
	done
	@echo "test-with-xxx-macros: PASS"

#
# COMMANDS --debug=aeqt
#
.PHONY: test
test: test-with-xxx-macros
test: EXTRA_BUILD_FLAGS= -D __DOMAIN__:=http://tests.com -D __LAYOUT__=$(__SRC__)/empty.txt
test: generator_test.m4
	$(M4) $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) \
	-D __BUILD_ROOT__=$(__BUILD_ROOT__) \
	--debug= \
	-D __PHASE__=TEST_PHASE \
	-D __TDIR__="$(__TMP__)/test" \
	-D __TARGET__=$(__TMP__)/test/dummy -D __FIRST__=$(__SRC__)/empty.txt \
	generator_test.m4 > $(__TMP__)/generator_test.out
	@cat $(__TMP__)/generator_test.out
	@! grep -q '^FAIL' $(__TMP__)/generator_test.out

# suppress errors: files may already be absent, which is expected during clean.
.IGNORE: clean compressed-files-clean realclean
.DEFAULT_GOAL := build

#
# __BUILD_ROOT__ is intentionally absent: GENERATE_MAKEFILE_PHASE emits [$(__BUILD_ROOT__)]/...
# so generated .mk files carry Make variable references, not literal paths.
#
ifeq ($(filter clean% realclean,$(MAKECMDGOALS)),)
$(__BUILD_ROOT__)/DEP/%.mk: $(__SRC__)/%.in.html $(__SRC__)/generator.m4 Makefile | $$(@D)/
	$(M4) -D __PHASE__=GENERATE_MAKEFILE_PHASE $(M4_FLAGS) \
		-D __STEM__=$* \
		-D __VENDOR__=$(__VENDOR__) \
		-D __TARGET__=$@ -D __FIRST__=$< \
		generator.m4 >$@ || rm $@
endif

# triggers the DEP pattern rule above for any stem missing its .mk
-include $(patsubst %.in.html,$(__BUILD_ROOT__)/DEP/%.mk,$(notdir $(wildcard $(__SRC__)/*.in.html)))

