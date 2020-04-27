#!/usr/bin/make -rsf

.SUFFIXES:
#.SUFFIXES: .html .m4 .png .gif

__EN__ 	:=en
__ES__ 	:=es

__SRC__	:=$(PWD)
__TMP__:=/tmp
__DOC__:=$(PWD)/_build/doc
__DEPS__:=$(PWD)/_build/dep
__ZIP__:=$(PWD)/_build/zip
__NAV__:=$(PWD)/_build/nav
__STATIC__:=static
__CSS__	:=css
__IMG__	:=img
__JS__ 	:=js
__FON__	:=fonts

GLYPH:=glyphicons-halflings-regular

__LAYOUT__:=$(__SRC__)/dummy-layout.html

##
##
##
__UNAME__:=$(shell uname -s)

##
##
##
##RM:= @-rm -f
RM:= @-rm 
RM2:= [ -e file ] && rm file
RMDIR:= @-rmdir

##
## M4
##
M4= $(shell which m4)
M4_FLAGS:= \
	-I $(__SRC__)
ifeq ($(__UNAME__),Linux)
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
	-D __EN__=$(__EN__) -D __ES__=$(__ES__) \
	-D __DOC__=$(__DOC__) -D __SRC__=$(__SRC__) 
##
## RULES START HERE
##
.SECONDEXPANSION:
##
## TREE
##
.PRECIOUS: $(PWD)/_build/%/
$(PWD)/_build/%/:
	@echo +++++++++++++++++++++ $@
	mkdir -p $@

.PRECIOUS: $(__TMP__)/%/
$(__TMP__)/%/:
	@echo --------------------- $@
	mkdir -p $@

##
## as first target build marks all langs as done one rule doesn't
## work, for now I will generate a normal rule in the dependencies or
## n rules here, if the suffix were different then the directories...
##
#$(addprefix $(__SRC__)/, $(PAGES)): $(__SRC__)/layout.html $(__SRC__)/generator.m4
#$(__SRC__)/%.html: $(__SRC__)/layout.html $(__SRC__)/generator.m4
##
######LAYOUT_FILES:= $(__LAYOUT__) $(__SRC__)/generator.m4 

#$(__DOC__)/navigation.txt


##
## NAVIGATION MAP
##
##$(__DEPS__)/%.d:   EXTRA_BUILD_FLAGS+=  -D __D__=$(dir $<) -D __N__=$(notdir $(basename $<)) -D __S__=$(suffix $<)
##$(__DEPS__)/%.txt: EXTRA_BUILD_FLAGS+=  -D __D__=$(dir $<) -D __N__=$(notdir $(basename $<)) -D __S__=$(suffix $<)
##%.html: EXTRA_BUILD_FLAGS+=  -D __D__=$(dir $<) -D __N__=$(notdir $(basename $<)) -D __S__=$(suffix $<)

## this rule matches the ones __NAVIGATION insert
##
$(__DOC__)/%.txt: | $$(@D)/
	echo --txt------------------ $(EXTRA_BUILD_FLAGS)
	$(M4) -D __PHASE__=MAKENAV $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) \
	-D __STEM__=$* -D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 >$@

## this rule collects all prerequisites declared on the *.d generates above
$(__DOC__)/navigation.txt: | $$(@D)/
	cat $^ > $@

.PHONY: clean
clean:: 
	$(RM) $(__DOC__)/navigation.txt

##
## ACTUAL PAGES
##
define do-build
$(M4) -D __PHASE__=MAKEBUILD $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) \
	-D __STEM__=__UNDEF__ \
	-D __TDIR__=$(@D) -D __TNAME__=$(@F) \
	-D __TARGET__=$@ -D __FIRST__=$< \
	generator.m4 >$@
endef

#$(__DOC__)/%.html: $(__SRC__)/$$(notdir %).in.html  | $$(@D)/
#	$(do-build)

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
##
## COPY ASSETS
##
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

##
## GZIPED TARGETS
##
GSUTIL_EXTRA_FLAGS:=
#$(__GZIP__)/$(__IMG__)/logo.png: GSUTIL_EXTRA_FLAGS=-h "Cache-Control:public,max-age=3600"
#$(__GZIP__)/$(__IMG__)/es.png: GSUTIL_EXTRA_FLAGS=-h "Cache-Control:public,max-age=86400"
#$(__GZIP__)/$(__IMG__)/us.png: GSUTIL_EXTRA_FLAGS=-h "Cache-Control:public,max-age=86400"
#$(__GZIP__)/$(__STATIC__)/%: GSUTIL_EXTRA_FLAGS+=-h "Cache-Control:public,max-age=86400"

define do-gzip
	gzip -c --no-name --rsyncable $< >$@
endef
##
## COMMANDS --debug=aeqt
##
.PHONY: test
test: EXTRA_BUILD_FLAGS= -D __DOMAIN__:=http://tests.com -D __LAYOUT__=$(__SRC__)/empty.txt
test: generator_test.m4
	$(M4) $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) \
	--debug=aeqt \
	-D __PHASE__=MAKEBUILD \
	-D __TDIR__="/tmp/test" -D __DOC__=$(__DOC__) -D __ZIP__=$(__ZIP__) \
	-D __TARGET__=/tmp/test/dummy -D __FIRST__=$(__SRC__)/empty.txt \
	generator_test.m4

.PHONY: build
## build: EXTRA_BUILD_FLAGS= -D __LAYOUT__=$(__LAYOUT__)
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
#publish: EXTRA_BUILD_FLAGS:= -D __DOMAIN__=http://www.tekii.com.ar -D __LAYOUT__=$(__LAYOUT__)
#publish: GSUTIL_EXTRA_FLAGS:= -D __DOMAIN__=http://www.tekii.com.ar
publish: #$(ALL_GZIP)
#	gsutil web set -m en/index.html -e en/404.html gs://www.teky.io
#	echo $^
#	echo $(EXTRA_BUILD_FLAGS)
#	echo $(GSUTIL_EXTRA_FLAGS)
#	@echo [[[ DONE $@ ]]]

.PHONY: all
all: build

##
## mmm... this rule will attemp to build everything first in order to
## make the dep list then delete all
##
.PHONY: clean
clean:: 
	@echo [[[ DONE $@ ]]]

.PHONY: cleangzip
cleangzip:
	rm -f $(ALL_GZIP)

.PHONY: realclean
realclean:: clean
	$(RMDIR) $(__DEPS__)
	$(RMDIR) $(__DOC__)
	$(RMDIR) $(__ZIP__)
	@echo [[[ DONE $@ ]]]

#gsutil -m rsync -ndr ../bucket/ gs://www.teky.io
#gsutil web set -m en/index.html -e en/404.html gs://www.teky.io
#gsutil acl ch -r -u AllUsers:R gs://www.teky.io/
# mimetype --brief /tmp/bucketgz/favicon.ico | tr -d '\n'

.IGNORE: clean cleangzip realclean obliterate  
.DEFAULT_GOAL := build
##
## MAKEDEPEND
## 
## THIS MUST BE THE FIRST RULE TO RUN, PLEASE ALL PREREQUISITES MUST PRE-EXIST
## 
########$(__DEPS__)/%.d: EXTRA_BUILD_FLAGS= -D __LAYOUT__=$(__LAYOUT__)
$(__DEPS__)/%.d: $(__SRC__)/%.in.html $(LAYOUT_FILES) $(__SRC__)/generator.m4 Makefile | $$(@D)/
	$(M4) $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) -D __PHASE__=MAKEDEPEND \
		-D __STEM__=$* \
		-D __ZIP__=$(__ZIP__) \
		-D __TARGET__=$@ -D __FIRST__=$< \
		generator.m4 >$@ || rm $@

# TODO: check what abaut this .PRECIOUS
#.PRECIOUS: $(__DEPS__)/%.d
## THIS FIRES THE RULE ABOVE
-include $(patsubst %.in.html,$(__DEPS__)/%.d,$(notdir $(wildcard $(__SRC__)/*.in.html)))

