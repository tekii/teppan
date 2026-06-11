#!/usr/bin/make -rsf

.SUFFIXES:
#.SUFFIXES: .html .m4 .png .gif

__SRC__	:=$(PWD)
__TMP__:=/tmp
__BUILD__:=$(PWD)/BUILD
__VENDOR__:=$(PWD)/VENDOR
__DOC__:=$(__BUILD__)/DOC
__DEP__:=$(__BUILD__)/DEP
__ZIP__:=$(__BUILD__)/ZIP
__NAV__:=$(__DOC__)

__LAYOUT__:=$(__SRC__)/dummy-layout.html

RM:= @-rm 
RMDIR:= @-rmdir

#
# M4
#
M4= $(shell which m4)
M4_FLAGS:= -I $(__SRC__)
##
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
	-D __DOC__=$(__DOC__) -D __SRC__=$(__SRC__) 
#
# RULES START HERE
#
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
#realclean::
#	-rmdir --ignore-fail-on-non-empty $(__VENDOR__)

#
# NAVIGATION MAP
#
#$(__DEP__)/%.d:   EXTRA_BUILD_FLAGS+=  -D __D__=$(dir $<) -D __N__=$(notdir $(basename $<)) -D __S__=$(suffix $<)
#$(__DEP__)/%.txt: EXTRA_BUILD_FLAGS+=  -D __D__=$(dir $<) -D __N__=$(notdir $(basename $<)) -D __S__=$(suffix $<)
#%.html: EXTRA_BUILD_FLAGS+=  -D __D__=$(dir $<) -D __N__=$(notdir $(basename $<)) -D __S__=$(suffix $<)

define do-generate-navigation
	$(M4) -D __PHASE__=GENERATE_NAVIGATION $(M4_FLAGS) \
	$(EXTRA_NAV_FLAGS) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 > $@
endef

$(__NAV__)/%/NAVIGATION.m4 : | $$(@D)/
	# we compare checksum to see if actually change and avoid the ripples of the circularity
	# cat $^ | cmp -s $@ - || cat $^ > $@ 
	cat $^ > $@ 

define do-generate-html
$(M4) -D __PHASE__=GENERATE_HTML $(M4_FLAGS) \
	$(EXTRA_HTML_FLAGS) \
	-D __TDIR__=$(@D) -D __TNAME__=$(@F) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 >$@
endef

define do-generate-deferred-mk
$(M4) -D __PHASE__=GENERATE_DEFERRED_MK $(M4_FLAGS) \
	$(EXTRA_DEFERRED_MK_FLAGS) \
	-D __TDIR__=$(@D) -D __TNAME__=$(@F) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 >$@ || rm $@
endef

##
## SITEMAP.XML
##
# contemplar el uso de $^, falta la dependencia con los
# sources de los htmls (puede que esto no sea necesario y no haya problema
# en regenerarlo siempre que tomemos la fecha del source
#$(__DOC__)/sitemap.xml : $(__SRC__)/sitemap.xml | $$(@D)/
#	$(M4) $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) \
#		-D __TNAME__=$(@F) \
#		-D __LIST__="$(filter-out 404.html,$(PAGES))" $(__SRC__)/sitemap.xml >$@

#
# COPY ASSETS TODO: this could be moved to an static generated rule 
#
$(__DOC__)/%.ico : | $$(@D)/
	cp $< $@

$(__DOC__)/%.png : | $$(@D)/
	cp $< $@

$(__DOC__)/%.gif : | $$(@D)/
	cp $< $@

$(__DOC__)/%.svg : | $$(@D)/
	cp $< $@

$(__DOC__)/%.jpg : | $$(@D)/
	cp $< $@	

$(__DOC__)/%.ttf : | $$(@D)/
	cp $< $@

$(__DOC__)/%.eot : | $$(@D)/
	cp $< $@

$(__DOC__)/%.woff : | $$(@D)/
	cp $< $@

$(__DOC__)/%.woff2 : | $$(@D)/
	cp $< $@

#
# GZIPED TARGETS
#
GSUTIL_EXTRA_FLAGS:=
#$(__GZIP__)/$(__IMG__)/logo.png: GSUTIL_EXTRA_FLAGS=-h "Cache-Control:public,max-age=3600"

define do-gzip
	gzip -c --no-name --rsyncable $< >$@
endef

.PHONY: build
build:
	@echo [[[ DONE $@ ]]]

#example.com/% : $(__ZIP__)/%
#	@echo "gsutil $(GSUTIL_EXTRA_FLAGS) -h "Content-Encoding:gzip" -h "Content-Type:$(shell mimetype --brief $< | tr -d '\n')" cp -a public-read -r $<  gs://$@"
#	@echo [[[ DONE $@ ]]]

define do-publish
	@echo "++++++ gsutil $(GSUTIL_EXTRA_FLAGS) -h "Content-Encoding:gzip" cp -a public-read -r $<  gs://$@"
	@echo [[[ PUBLISHED $@ ]]]
endef

.PHONY: publish
publish: #$(ALL_GZIP)
#	@echo [[[ DONE $@ ]]]

.PHONY: all
all: build

##
## mmm... this rule will attemp to build everything first in order to
## make the dep list then delete all
##
.PHONY: clean
clean : clean-build clean-asset clean-gzip clean-makefile clean-navigation
	@echo [[[ DONE $@ ]]]

.PHONY: realclean
realclean:: clean
	$(RMDIR) $(__DEP__)
	$(RMDIR) $(__DOC__)
	$(RMDIR) $(__ZIP__)
	@echo [[[ DONE $@ ]]]

#gsutil -m rsync -ndr ../bucket/ gs://www.teky.io
#gsutil web set -m en/index.html -e en/404.html gs://www.teky.io
#gsutil acl ch -r -u AllUsers:R gs://www.teky.io/
# mimetype --brief /tmp/bucketgz/favicon.ico | tr -d '\n'

#
# COMMANDS --debug=aeqt
#
.PHONY: test
test: EXTRA_BUILD_FLAGS= -D __DOMAIN__:=http://tests.com -D __LAYOUT__=$(__SRC__)/empty.txt
test: generator_test.m4
	$(M4) $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) \
	--debug= \
	-D __PHASE__=TEST_PHASE \
	-D __TDIR__="/tmp/test" -D __DOC__=$(__DOC__) -D __ZIP__=$(__ZIP__) \
	-D __TARGET__=/tmp/test/dummy -D __FIRST__=$(__SRC__)/empty.txt \
	generator_test.m4 > /tmp/generator_test.out
	@cat /tmp/generator_test.out
	@! grep -q '^FAIL' /tmp/generator_test.out

.IGNORE: clean cleangzip realclean obliterate  
.DEFAULT_GOAL := build

#
# TEMPLATE MAKEFILES
# 
$(__DEP__)/%.mk: $(__SRC__)/%.in.html $(__SRC__)/generator.m4 Makefile | $$(@D)/
	$(M4) -D __PHASE__=GENERATE_MAKEFILE $(M4_FLAGS) \
		-D __STEM__=$* \
		-D __NAV__=$(__NAV__) \
		-D __ZIP__=$(__ZIP__) \
		-D __VENDOR__=$(__VENDOR__) \
		-D __TARGET__=$@ -D __FIRST__=$< \
		generator.m4 >$@ || rm $@

# TODO: check what abaut this .PRECIOUS
#.PRECIOUS: $(__DEP__)/%.d
# THIS INCLUDE FIRES THE RULE ABOVE
-include $(patsubst %.in.html,$(__DEP__)/%.mk,$(notdir $(wildcard $(__SRC__)/*.in.html)))
