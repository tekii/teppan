##
## NICE HEADER
##
#.SUFFIXES:
#.SUFFIXES: .html .amp.html .m4 .d

__EN__ 	:=en
__ES__ 	:=es

__SRC__	:=.

__ROOT__:=/tmp/bucket
__GZIP__:=/tmp/bucketgz
__STATIC__:=static
__CSS__	:=css
__IMG__	:=img
__JS__ 	:=js
__FON__	:=fonts
__DEPS__:=/tmp/bucket/deps

HTML_EXT:=.html
AMP__EXT:=.amp.html

GLYPH:=glyphicons-halflings-regular

PAGES := 404.html index.html about.html contact.html services.html customers.html home.html

##
##
##
__UNAME__:=$(shell uname -s)

##
##
##
RM:= @-rm -f
#RM:= [ -e file ] && rm file
RMDIR:= @-rmdir

##
## M4
## /usr/local/Cellar/autoconf/2.69/share/autoconf/m4sugar/m4sugar.m4f
## /usr/share/autoconf/m4sugar/m4sugar.m4f
M4= $(shell which m4)
ifeq ($(__UNAME__),Linux)
M4_FLAGS:= \
	-I /usr/share/autoconf \
	-R /usr/share/autoconf/m4sugar/m4sugar.m4f \
	-D __RP__=$(shell which realpath)
else
M4_FLAGS:= \
	-I /usr/local/Cellar/autoconf/2.69/share/autoconf \
	-R /usr/local/Cellar/autoconf/2.69/share/autoconf/m4sugar/m4sugar.m4f \
	-D __RP__=$(shell which grealpath)
endif
M4_FLAGS+= \
	-D __EN__=$(__EN__) -D __ES__=$(__ES__) \
	-I $(__SRC__)

##
## RULES START HERE
##
.SECONDEXPANSION:
##
## TREE
##
.PRECIOUS: $(__ROOT__)/%/
$(__ROOT__)/%/:
	echo 'trulala' $@
	mkdir -p $@
##
## as first target build marks all langs as done one rule doesn't
## work, for now I will generate a normal rule in the dependencies or
## n rules here, if the suffix were different then the directories...
##
#$(addprefix $(__SRC__)/, $(PAGES)): $(__SRC__)/layout.html $(__SRC__)/tpy.m4
#$(__SRC__)/%.html: $(__SRC__)/layout.html $(__SRC__)/tpy.m4
##
LAYOUT_FILES:= $(__SRC__)/layout.html $(__SRC__)/tpy.m4

$(__SRC__)/%.html: EXTRA_BUILD_FLAGS+= -D __IMAGES__=$(__IMG__)

define build-page
$(M4) $(M4_FLAGS) -D __DO__=MAKEBUILD \
	$(EXTRA_BUILD_FLAGS) \
	-D __BASE__=$(@D) -D __ROOT__=$(__ROOT__) -D __FNAME__=$(@F) \
	tpy.m4 >$@
endef

$(__ROOT__)/%.html : $(__SRC__)/%.html $(LAYOUT_FILES) | $$(@D)/
	$(build-page)

$(__ROOT__)/$(__EN__)/%.html : $(__SRC__)/%.html $(LAYOUT_FILES) | $$(@D)/
	$(build-page)

$(__ROOT__)/$(__ES__)/%.html : $(__SRC__)/%.html $(LAYOUT_FILES) | $$(@D)/
	$(build-page)
##
## SITEMAP.XML
##
# contemplar el uso de $^, falta la dependencia con los
# sources de los htmls (puede que esto no sea necesario y no haya problema
# en regenerarlo siempre que tomemos la fecha del source
$(__ROOT__)/sitemap.xml : $(__SRC__)/sitemap.xml | $(__ROOT__)/
	$(M4) $(M4_FLAGS) $(EXTRA_BUILD_FLAGS) \
		-D __FNAME__=$(@F) \
		-D __LIST__="$(filter-out 404.html,$(PAGES))" $(__SRC__)/sitemap.xml >$@
##
## COPY STATICS
##
$(__ROOT__)/$(__STATIC__)/% : $(__SRC__)/% | $$(@D)/
	cp $< $@
##
## GZIPED TARGETS
##
GSUTIL_EXTRA_FLAGS:=
#$(__GZIP__)/$(__IMG__)/logo.png: GSUTIL_EXTRA_FLAGS=-h "Cache-Control:public,max-age=3600"
#$(__GZIP__)/$(__IMG__)/es.png: GSUTIL_EXTRA_FLAGS=-h "Cache-Control:public,max-age=86400"
#$(__GZIP__)/$(__IMG__)/us.png: GSUTIL_EXTRA_FLAGS=-h "Cache-Control:public,max-age=86400"

$(__GZIP__)/$(__STATIC__)/%: GSUTIL_EXTRA_FLAGS+=-h "Cache-Control:public,max-age=86400"

$(__GZIP__)/%: $(__ROOT__)/% | $$(@D)/
	gzip -c --no-name --rsyncable $< >$@
	#gsutil $(GSUTIL_EXTRA_FLAGS) -h "Content-Encoding:gzip" -h "Content-Type:$(shell mimetype --brief $< | tr -d '\n')" cp -a public-read -r $@  gs://www.tekii.com.ar$(subst $(__GZIP__),,$(dir $@))

##
## COMMANDS --debug=aeqt
##
PHONY += testm4
testm4:
	$(M4) $(M4_FLAGS) --debug= -D __FNAME__="test_tpy.m4" -D __BASE__=$(@D) -D __ROOT__=$(__ROOT__) -D __LIST__="$(filter-out 404.html,$(PAGES))" test_tpy.m4

PHONY += build
build: EXTRA_BUILD_FLAGS= -D __DOMAIN__=http://www.tekii.com.ar
build:
	@echo [[[ DONE $@ ]]]

PHONY += publish
publish: EXTRA_BUILD_FLAGS= -D __DOMAIN__=http://www.tekii.com.ar
publish: build #$(ALL_GZIP)
#	gsutil web set -m en/index.html -e en/404.html gs://www.teky.io
	echo $^
	@echo [[[ DONE $@ ]]]


PHONY += all
all: build

##
## mmm... this rule will attemp to build everything first in order to
## make the dep list then delete all
##
PHONY += clean
clean::
	@echo [[[ DONE $@ ]]]

PHONY += cleangzip
cleangzip:
	rm -f $(ALL_GZIP)

PHONY += realclean
realclean:: clean
	$(RM) $(patsubst %,$(__DEPS__)/%.d,$(basename $(PAGES)))
	$(RMDIR) $(__ROOT__)/$(__STATIC__)/$(__IMG__)/
	$(RMDIR) $(__ROOT__)/$(__STATIC__)/$(__FON__)/
	$(RMDIR) $(__ROOT__)/$(__STATIC__)
	$(RMDIR) $(__DEPS__)
	$(RMDIR) $(__ROOT__)
#	$(RMDIR) $(__GZIP__)
	@echo [[[ DONE $@ ]]]

#gsutil -m rsync -ndr ../bucket/ gs://www.teky.io
#gsutil web set -m en/index.html -e en/404.html gs://www.teky.io
#gsutil acl ch -r -u AllUsers:R gs://www.teky.io/
# mimetype --brief /tmp/bucketgz/favicon.ico | tr -d '\n'

.IGNORE: clean cleangzip realclean
.PHONY: $(PHONY)
.DEFAULT_GOAL := build
##
## MAKEDEPEND
##
$(__DEPS__)/%.d: $(__SRC__)/%.html $(LAYOUT_FILES) Makefile | $$(@D)/
	$(M4) $(M4_FLAGS) -D __DO__=MAKEDEPEND \
		-D __FNAME__=$< -D __BASE__=$(@D) \
		-D __ROOT__=$(__ROOT__) -D __SRC__=$(__SRC__) \
		tpy.m4 >$@ || rm $@
.PRECIOUS: $(__DEPS__)/%.d
# ignoring error here its important
-include $(patsubst %,$(__DEPS__)/%.d,$(basename $(PAGES)))
