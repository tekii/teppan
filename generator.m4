dnl 
dnl DIVERTS
dnl 
m4_define([_m4_divert(DEFAULT)], 0)
m4_define([_m4_divert(DEPEND)], 1)
m4_define([_m4_divert(SITEMAP)], 2)
m4_define([_m4_divert(HEADER)], 3)
m4_define([_m4_divert(BODY)], 4)
m4_define([_m4_divert(AMP_CUSTOM_STYLES)], 5)
m4_define([_m4_divert(AMP_CUSTOM_ELEMENTS)], 6)
m4_define([_m4_divert(NAVIGATION)], 7)
m4_define([_m4_divert(BUILD)], 8)
m4_define([_m4_divert(PAPER)], 9)
m4_define([_m4_divert(PUBLISH)], 10)

dnl
dnl CONSTANTS
dnl
m4_define([__TEKII__],[<strong>TEKii$1</strong>])
m4_define([__TEKII_SRL_]_,__TEKII__([ SRL]))

m4_define([__REL_AS_CANONICAL__],canonical)
m4_define([__REL_AS_ALTERNATE__],alernate)
m4_define([__REL_AS_AMPHTML__],amphtml)

dnl
dnl LANG CONDITIONALS
dnl
m4_define([__LANGS__],[[en,[English]],[es,[Español]]])

m4_define([__FOREACH_LANG],
[m4_foreach([Iter], [__LANGS__],
            [m4_pushdef([$1])m4_pushdef([$2])m4_define([$1],m4_car(Iter))m4_define([$2],m4_cdr(Iter))$3[]m4_popdef([$2])m4_popdef([$1])])])

m4_define([__FOREACH_LANG_EXCEPT],
[m4_foreach([Iter], [__LANGS__],
            [m4_pushdef([$2])m4_pushdef([$3])m4_define([$2],m4_car(Iter))m4_define([$3],m4_cdr(Iter))m4_if(__L__,$1,[],[$4])m4_popdef([$3])m4_popdef([$2])])])

m4_define([__LOOKUP_LANG_NAME],
[m4_if([$#], 0, [m4_fatal([$0: cannot be called without arguments]],
       [$#], 1, [m4_fatal([$0: cannot be called with 1 arguments])],
       [$#], 2, [UNDEFINED LANG],
       [m4_if($1,$2,$3,[__LOOKUP_LANG_NAME($1,m4_shift3($@))])])])

m4_define([__LANG_NAME], [__LOOKUP_LANG_NAME($1,m4_unquote(__LANGS__))])
m4_define([__LANG_NAME__], __LANG_NAME(__LANG__))

m4_define([__ESEN],
m4_case(__LANG__,__ES__,$1,__EN__,$2))

m4_define([__ENES],
m4_case(__LANG__,__EN__,$1,__ES__,$2))

#
# calculate path jump relative to __TDIR__ or $2
# TODO: strip fragments #xxx
#
m4_define([__HREF],
[m4_esyscmd_s(__REALPATH__ --canonicalize-missing $1 --relative-to=m4_default([$2],[__TDIR__]))])

dnl[m4_divert_text([PAPER],[<!-- __file__ __line__ --$1-- -->])[]

m4_define([__FNAME],
[m4_bregexp($1,[\([^/]+\..+\)$], [\1])])

m4_define([__RDATE],
[m4_chomp_all(m4_esyscmd(date --reference=$1 +%Y-%m-%d))])

dnl
dnl LOCALIZE MACROS
dnl $1 page key
dnl $2 lang key
dnl
m4_define([__LOCALIZE_URL_NAME],[$2-$3])
m4_define([__LOCALIZE_URL_PATH],[$1/$2/$3])
m4_define([__LOCALIZE_URL_NULL],[$1/$3])

dnl
dnl WITH_LAYOUT MACRO
dnl
m4_define([__WITH_LAYOUT],[dnl
m4_pushdef([__LAYOUT__],m4_default($1,__LAYOUT__))dnl
$2dnl
m4_popdef([__LAYOUT__])dnl
dnl next line its a temporary hack
m4_define([__LAYOUT__],m4_default($1,__LAYOUT__))dnl
])

dnl
dnl WITH_LANG MACRO
dnl
m4_define([__WITH_LANG],[
m4_foreach([__L__], [$1],[
m4_pushdef([__LANG__],__L__)
$2dnl
m4_popdef([__LANG__])
])dnl foreach
])

dnl
dnl WITH_FIRST_LANG_AS_CANONICAL MACRO
dnl this is a future macro thats set __RELATION__
dnl
m4_define([__WITH_FIRST_LANG_AS_CANONICAL],[
m4_foreach([__L__], [$1],[
m4_pushdef([__LANG__],__L__)
$2dnl
m4_popdef([__LANG__])
])dnl foreach
])


dnl
dnl WITH_DOMAIN MACRO
dnl
m4_define([__WITH_DOMAIN],[
m4_foreach([__D__], [$1],[
m4_pushdef([__DOMAIN__],__D__)
m4_set_add([__ROOTS__],__DOC__/__DOMAIN__)dnl
$2dnl
m4_popdef([__DOMAIN__])
])dnl foreach
])

dnl
dnl WITH_NAME MACRO
dnl
m4_define([__WITH_NAME],[dnl
])
dnl

dnl
dnl MAKE_PAGE MACRO
dnl
dnl $1 LinkType
dnl
m4_define([__MAKE_PAGE],[
m4_pushdef([__STEM__],$2(__DOMAIN__,__L__,__STEM__))
m4_pushdef([__RELATION__],$1)
dnl TODO rewiew next 2 lines
dnl m4_set_add([__CURRENT_BUILD_TARGETS__],__DOC__/__STEM__.html)dnl
m4_set_add([__BUILD_TARGETS__],m4_quote(__DOC__/__DOMAIN__,__DOC__/__STEM__.html))dnl
dnl
m4_divert_push([DEPEND])
m4_text_box(__STEM__ DEPENDS BEGINS,[+])
__DOC__/__STEM__.html : __LAYOUT__
__DOC__/__STEM__.html : __SRC__/generator.m4
__DOC__/__STEM__.html : EXTRA_BUILD_FLAGS+= -D [__LAYOUT__]=__LAYOUT__ -D [__DOMAIN__]=__DOMAIN__ -D [__LANG__]=__LANG__ -D [__RELATION__]=__RELATION__ -D [__ROOT__]=__DOC__/__DOMAIN__ -D [__VENDOR__]=__VENDOR__
__DOC__/__STEM__.html : __FIRST__ | $$(@D)/ ; [$(do-build)]
.INTERMEDIATE : __ZIP__/__STEM__.html
__ZIP__/__STEM__.html : GZIP_EXTRA_FLAGS:= 
__ZIP__/__STEM__.html : __DOC__/__STEM__.html | $$(@D)/ ;  [$(do-gzip)]
.INTERMEDIATE : __STEM__.html
__STEM__.html : GSUTIL_EXTRA_FLAGS+= -h "Content-Type:$(shell mimetype --brief __DOC__/__STEM__.html | tr -d '\n')"
__STEM__.html : GSUTIL_EXTRA_FLAGS+= -h "Cache-Control:public,max-age=86400"
__STEM__.html : __ZIP__/__STEM__.html ; [$(do-publish)]
dnl
m4_pushdef([__DOMAIN__],m4_bpatsubst(__DOMAIN__,[\.],[-]))dnl
.PHONY : __DOMAIN__-refresh
__DOMAIN__-refresh : __DOC__/__STEM__.html
.PHONY : __DOMAIN__
__DOMAIN__ : __STEM__.html
publish : __DOMAIN__
m4_popdef([__DOMAIN__])dnl
dnl 
build : __DOC__/__STEM__.html
clean :: ; [$(RM)] -f __DOC__/__STEM__.html
realclean :: ; [$(RM)] -f __TARGET__
m4_text_box(__STEM__ DEPENDS ENDS  ,[-])
m4_divert_pop([DEPEND])
dnl
m4_divert_push([NAVIGATION])dnl
<!-- nothing to see here yet -->
m4_divert_pop([NAVIGATION])
dnl
m4_popdef([__RELATION__])
m4_popdef([__STEM__])
])

dnl
dnl ASSET MACRO
dnl $1 source relative asset URI
dnl
m4_define([__ASSET],[__HREF([__DOC__/$1])[]dnl
m4_divert_push([DEPEND])
m4_text_box($1 ASSET BEGINS,[+])
dnl TODO next loop copies the asset files in all domains not in the ones that
dnl actually has a dependency whit it, this is an error.
m4_set_foreach([__ROOTS__],[__R__],[dnl
m4_car(__R__)/$1 : __SRC__/$1 
clean:: ; -rm -f m4_car(__R__)/$1 
])dnl
m4_set_foreach([__BUILD_TARGETS__],[__I__],[dnl
m4_unquote(m4_cdr(__I__)) : m4_car(__I__)/$1
])dnl
m4_text_box($1 ASSET ENDS  ,[-])
m4_divert_pop([DEPEND])
])

dnl
dnl INCL MACRO
dnl source relative filename
dnl
m4_define([__INCL],[
m4_divert_text([DEPEND],[
m4_text_box($1 INCLUDE BEGINS,[+])
m4_set_foreach([__BUILD_TARGETS__],[__I__],[dnl
m4_unquote(m4_cdr(__I__)) : $1
])dnl
m4_text_box($1 INCLUDE ENDS  ,[-])
])[]m4_include([$1])])

dnl
dnl NAVIGATION_ITEM
dnl
m4_define([__NAVIGATION_ITEM],[$1[]dnl
m4_divert_text([NAVIGATION],[__NAVIGATION_ITEM_TEMPLATE([$1],$2,$3)])dnl
])

dnl
dnl TODO move some dependencies to the item instead 
dnl
m4_define([__NAVIGATION],[dnl
m4_divert_text([DEPEND],[
m4_text_box(__STEM__ NAVIGATION BEGINS ,[+])
__DOC__/__STEM__.txt : __FIRST__
__DOC__/navigation.txt : __DOC__/__STEM__.txt
m4_set_foreach([__BUILD_TARGETS__],[__BT__],[dnl
m4_unquote(m4_cdr(__BT__)) : __DOC__/navigation.txt
])dnl
clean :: ; [$(RM)] -f __DOC__/__STEM__.txt
clean :: ; [$(RM)] -f __DOC__/navigation.txt 
m4_text_box(__STEM__ NAVIGATION ENDS   ,[-])
])
m4_if(__PHASE__,[MAKEBUILD],[m4_include(__DOC__/navigation.txt)],[])dnl
])

dnl
dnl 
dnl PAGE PROCESS STARTS HERE
dnl PAGE PROCESS STARTS HERE
dnl PAGE PROCESS STARTS HERE
dnl
dnl FIRST LOAD THE CONFIG DEFINITIONS
dnl
m4_include([./configure.m4])
dnl
dnl HERE WE FILL THE DIVERSIONS
dnl
m4_include(__FIRST__)
dnl
dnl NOW THE LAYOUT CONSUME THE DIVERSIONS
dnl
m4_include(__LAYOUT__)
dnl
dnl AND FINALLY CHOOSE WHAT TO EMIT
dnl
m4_case(__PHASE__,
[MAKEBUILD],[
m4_divert_text([DEFAULT],[m4_undivert([BUILD])])
m4_cleardivert([SITEMAP])
m4_cleardivert([DEPEND])
m4_cleardivert([AMP_CUSTOM_STYLES])
m4_cleardivert([AMP_CUSTOM_ELEMENTS])
m4_cleardivert([NAVIGATION])
m4_divert_text([DEFAULT],[
<!-- PAPER TRAIL -------------------------------- -->
m4_undivert([PAPER])
<!-- PAPER TRAIL--------------------------------- -->])
m4_cleardivert([PUBLISH])
],
[MAKEDEPEND],[
m4_divert_text([DEFAULT],[m4_undivert([DEPEND])])
m4_cleardivert([SITEMAP])
m4_cleardivert([HEADER])
m4_cleardivert([BODY])
m4_cleardivert([AMP_CUSTOM_STYLES])
m4_cleardivert([AMP_CUSTOM_ELEMENTS])
m4_cleardivert([NAVIGATION])
m4_cleardivert([BUILD])
m4_cleardivert([PAPER])
m4_cleardivert([PUBLISH])
],
[MAKENAV],[
m4_divert_text([DEFAULT],[m4_undivert([NAVIGATION])])
m4_cleardivert([SITEMAP])
m4_cleardivert([HEADER])
m4_cleardivert([BODY])
m4_cleardivert([AMP_CUSTOM_STYLES])
m4_cleardivert([AMP_CUSTOM_ELEMENTS])
m4_cleardivert([DEPEND])
m4_cleardivert([BUILD])
m4_cleardivert([PAPER])
m4_cleardivert([PUBLISH])
],
[MAKEPUB],[
m4_divert_text([DEFAULT],[m4_undivert([PUBLISH])])
m4_cleardivert([SITEMAP])
m4_cleardivert([HEADER])
m4_cleardivert([BODY])
m4_cleardivert([AMP_CUSTOM_STYLES])
m4_cleardivert([AMP_CUSTOM_ELEMENTS])
m4_cleardivert([DEPEND])
m4_cleardivert([BUILD])
m4_cleardivert([PAPER])
m4_cleardivert([NAVIGATION])
],
[
dnl m4_fatal([Unmached [__PHASE__]:__PHASE__],[1])
m4_cleardivert([DEPEND])
m4_cleardivert([SITEMAP])
m4_cleardivert([HEADER])
m4_cleardivert([BODY])
m4_cleardivert([AMP_CUSTOM_STYLES])
m4_cleardivert([AMP_CUSTOM_ELEMENTS])
m4_cleardivert([NAVIGATION])
m4_cleardivert([BUILD])
m4_cleardivert([PAPER])
m4_cleardivert([PUBLISH])
])
