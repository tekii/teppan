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
m4_define([__ES__],[es])
m4_define([__EN__],[en])
m4_define([__BR__],[br])
m4_define([__REL_AS_CANONICAL__],canonical)
m4_define([__REL_AS_ALTERNATE__],alernate)
m4_define([__REL_AS_AMPHTML__],amphtml)

dnl
dnl LANG CONDITIONALS
dnl
m4_define([__LANGS__],[[en,[English]],[es,[Español]],[br,[Português]]])

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
m4_define([__HREF],[m4_esyscmd_s(__REALPATH__ --canonicalize-missing $1 --relative-to=m4_default([$2],[__TDIR__]))])

# 
# REL(URL,[BASE]) MACRO 
#
m4_define([__RELATIVE],[$1])dnl
#
# ABS(URL,[BASE|SCHEME]) MACRO
#
m4_define([__ABSOLUTE],[m4_esyscmd_s(helper-url-absolute --scheme http --start __DOC__ --path $1)])dnl

dnl[m4_divert_text([PAPER],[<!-- __file__ __line__ --$1-- -->])[]

m4_define([__FNAME],
[m4_bregexp($1,[\([^/]+\..+\)$], [\1])])

m4_define([__RDATE],
[m4_chomp_all(m4_esyscmd(date --reference=$1 +%Y-%m-%d))])

dnl
dnl LOCALIZE_*(DOMAIN,LANG,STEM) MACROS
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
dnl next line its a temporary hack (but i forgot the problem... :( )
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
dnl WITH_STEM(STEM) MACRO
dnl
m4_define([__WITH_STEM],[
m4_pushdef([__STEM__],[$1])       
$2dnl
m4_popdef([__STEM__])       
])

m4_define([__UP],[m4_translit($1,[abcdefghijklmnopqrstuvwxyz./],[ABCDEFGHIJKLMNOPQRSTUVWXYZ__])])

dnl
dnl MAKE_PAGE MACRO
dnl
dnl $1 LinkType
dnl
m4_define([__MAKE_PAGE],[
dnl TODO: add some check in the composing of the id to avoid clashes
m4_pushdef([__LOCAL_URL_ID__],__UP(__[]__STEM__[]_[]__LANG__[]_URL__))
m4_pushdef([__PATH_STEM__],$2(__DOMAIN__,__L__,__STEM__))
m4_pushdef([__RELATION__],$1)
dnl TODO rewiew next 2 lines
dnl m4_set_add([__CURRENT_BUILD_TARGETS__],__DOC__/__PATH_STEM__.html)dnl
m4_set_add([__BUILD_TARGETS__],m4_quote(__DOC__/__DOMAIN__,__DOC__/__PATH_STEM__.html))dnl
dnl
m4_divert_push([DEPEND])
m4_text_box(__STEM__ DEPENDS BEGINS,[+])
[#] NAVIGATION
__NAV__/__PATH_STEM__ : __SRC__/generator.m4
__NAV__/__PATH_STEM__ : EXTRA_NAV_FLAGS+= -D [__LANG__]=__LANG__ -D [__STEM__]=__STEM__ -D [__LOCAL_URL_ID__]=__LOCAL_URL_ID__ 
__NAV__/__PATH_STEM__ : __FIRST__ | $$(@D)/ ; [$(do-navigation)]
clean-navigation :: ; -rm -f __NAV__/__PATH_STEM__
__NAV__/__DOMAIN__/NAVIGATION : __NAV__/__PATH_STEM__
clean-navigation :: ; -rm -f __NAV__/__DOMAIN__/NAVIGATION
dnl
[#] BUILD 
dnl TODO: is VENDOR really needed in this PHASE?
[#] __DOC__/__PATH_STEM__.html : __NAV__/__DOMAIN__/NAVIGATION
__DOC__/__PATH_STEM__.html : __LAYOUT__
__DOC__/__PATH_STEM__.html : __SRC__/generator.m4
__DOC__/__PATH_STEM__.html : EXTRA_BUILD_FLAGS+= -D [__LAYOUT__]=__LAYOUT__ -D [__DOMAIN__]=__DOMAIN__ -D [__LANG__]=__LANG__ -D [__DOC__]=__DOC__ -D [__STEM__]=__STEM__ -D [__LOCAL_URL_ID__]=__LOCAL_URL_ID__ -D [__RELATION__]=__RELATION__ -D [__ROOT__]=__DOC__/__DOMAIN__ -D [__VENDOR__]=__VENDOR__ -D [__NAV__]=__NAV__   
__DOC__/__PATH_STEM__.html : __FIRST__ | $$(@D)/ __NAV__/__DOMAIN__/NAVIGATION ; [$(do-build)]
clean-build :: ; -rm -f __DOC__/__PATH_STEM__.html
dnl
[#] ZIP
.INTERMEDIATE : __ZIP__/__PATH_STEM__.html
__ZIP__/__PATH_STEM__.html : GZIP_EXTRA_FLAGS:= 
__ZIP__/__PATH_STEM__.html : __DOC__/__PATH_STEM__.html | $$(@D)/ ;  [$(do-gzip)]
clean-gzip :: ; -rm -f __ZIP__/__PATH_STEM__.html
dnl
[#] PUBLISH
.INTERMEDIATE : __PATH_STEM__.html
__PATH_STEM__.html : GSUTIL_EXTRA_FLAGS+= -h "Content-Type:$(shell mimetype --brief __DOC__/__PATH_STEM__.html | tr -d '\n')"
__PATH_STEM__.html : GSUTIL_EXTRA_FLAGS+= -h "Cache-Control:public,max-age=86400"
__PATH_STEM__.html : __ZIP__/__PATH_STEM__.html ; [$(do-publish)]
dnl
m4_pushdef([__DOMAIN__],m4_bpatsubst(__DOMAIN__,[\.],[-]))dnl
.PHONY : build-__DOMAIN__
build-__DOMAIN__ : __DOC__/__PATH_STEM__.html
.PHONY : __DOMAIN__
__DOMAIN__ : __PATH_STEM__.html
publish : __DOMAIN__
m4_popdef([__DOMAIN__])dnl
dnl 
build : __DOC__/__PATH_STEM__.html
realclean :: ; [$(RM)] -f __TARGET__
m4_text_box(__STEM__ DEPENDS ENDS  ,[-])
m4_divert_pop([DEPEND])
dnl
m4_divert_push([NAVIGATION])dnl
m4_text_box(__PATH_STEM__,[-])
[m4_define](m4_dquote(__LOCAL_URL_ID__),m4_dquote(__DOC__/__PATH_STEM__.html))
[m4_set_add](m4_quote(__UP(__[]__STEM__[]_ALTERNATES__),m4_dquote(m4_dquote(__LANG__,__LOCAL_URL_ID__))))
m4_divert_pop([NAVIGATION])
dnl
m4_popdef([__RELATION__])
m4_popdef([__PATH_STEM__])
m4_popdef([__LOCAL_URL_ID__])
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
clean-asset :: ; -rm -f m4_car(__R__)/$1 
])dnl
m4_set_foreach([__BUILD_TARGETS__],[__I__],[dnl
m4_unquote(m4_cdr(__I__)) : m4_car(__I__)/$1
])dnl
m4_text_box($1 ASSET ENDS  ,[-])
m4_divert_pop([DEPEND])dnl
])

dnl
dnl INCL() MACRO
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
dnl NAV_ITEM(TEXT,URL,FRAGMENT)
dnl
m4_define([__NAV_ITEM],[m4_divert_text([NAVIGATION],
m4_dquote([m4_set_add](m4_dquote(__NAV__ITEMS__),m4_dquote(m4_dquote(__LANG__,$2,$3,$4))))dnl
)
])

dnl
dnl RENDER(LIST,TEMPLATE)
dnl
m4_define([__RENDER],[dnl
m4_pushdef([$0_T],[$2])dnl
m4_foreach([__I__],[$1],[m4_indir([$0_T],__I__)])dnl
m4_popdef([$0_T])dnl
])

dnl
dnl RENDER_SET(SET,TEMPLATE)
dnl
m4_define([__RENDER_SET],[dnl
m4_pushdef([$0_T],[$2])dnl
m4_set_foreach([$1],[__I__],[m4_indir([$0_T],__I__)])dnl
m4_popdef([$0_T])dnl
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
m4_if(__PHASE__,[MAKEBUILD],[m4_include(__NAV__/__DOMAIN__/NAVIGATION)],[])dnl
dnl m4_sinclude(__NAV__/__DOMAIN__/NAVIGATION)
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
