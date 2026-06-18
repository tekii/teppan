dnl 
dnl DIVERTS, when M4 load the script the active divert is KILL because the m4_init
dnl 
m4_define([_m4_divert(DEFAULT)], 0)
m4_define([_m4_divert(MAKEFILE)], 1)
dnl m4_define([_m4_divert(SITEMAP)], 2)
m4_define([_m4_divert(HEAD)], 3)
m4_define([_m4_divert(MAIN)], 4)
m4_define([_m4_divert(CUSTOM_STYLES)], 5)
m4_define([_m4_divert(CUSTOM_ELEMENTS)], 6)
m4_define([_m4_divert(NAVIGATION)], 7)
m4_define([_m4_divert(HTML)], 8)
m4_define([_m4_divert(DEFERRED_MK)], 9)
m4_define([_m4_divert(EPILOG)], 10)
m4_define([_m4_divert(TESTS)], 11)

dnl
dnl
dnl
m4_define([__MAIN_PUSH__],[m4_divert_push([MAIN])<!-- ])
m4_define([__MAIN_POP__],[ -->m4_newline([])[]m4_divert_pop([MAIN])])
m4_define([__HEAD_PUSH__],[m4_divert_push([HEAD])<!-- ])
m4_define([__HEAD_POP__],[ -->m4_newline([])[]m4_divert_pop([HEAD])])

dnl
dnl CONSTANTS
dnl
m4_define([__ES__],[es])
m4_define([__EN__],[en])
m4_define([__BR__],[br])
dnl m4_define([__REL_AS_CANONICAL__],canonical)
dnl m4_define([__REL_AS_ALTERNATE__],alernate)
dnl m4_define([__REL_AS_AMPHTML__],amphtml)

dnl
dnl LANG CONDITIONALS
dnl
m4_define([__LANGS__],[[en,[English]],[es,[Español]],[br,[Português]]])

m4_define([__LOOKUP_LANG_NAME],
[m4_if([$#], 2, [UNDEFINED LANG],
       [m4_if($1,$2,$3,[__LOOKUP_LANG_NAME($1,m4_shift3($@))])])])

m4_define([__LANG_NAME], [__LOOKUP_LANG_NAME($1,m4_unquote(__LANGS__))])
m4_define([__LANG_NAME__], __LANG_NAME(__LANG__))

dnl
dnl __LANG__'s internal codes (en/es/br) are used for URL paths and are not
dnl all valid BCP 47 language tags (notably __BR__'s "br" is the ISO 639-1
dnl code for Breton, not Brazilian Portuguese). __LANG_TAG maps an internal
dnl code to the BCP 47 tag to use in HTML lang/hreflang attributes.
dnl
m4_define([__LANG_TAGS__],[[en,[en]],[es,[es]],[br,[pt-BR]]])
m4_define([__LANG_TAG], [__LOOKUP_LANG_NAME($1,m4_unquote(__LANG_TAGS__))])
m4_define([__LANG_TAG__], __LANG_TAG(__LANG__))

m4_define([__ESEN],
[m4_case(__LANG__,__ES__,[$1],__EN__,[$2])])

m4_define([__ENES],
[m4_case(__LANG__,__EN__,[$1],__ES__,[$2])])

#
# calculate path jump relative to __TDIR__ or $2
# TODO: strip fragments #xxx
#
m4_define([__HREF],[m4_esyscmd_s(__REALPATH__ --canonicalize-missing $1 --relative-to=m4_default([$2],[__TDIR__]))])

#
# ABS(URL,[BASE|SCHEME]) MACRO
# turns a __DOC__-relative filesystem path into an absolute URL by
# treating the first path component (relative to __DOC__) as the host
#
m4_define([__ABSOLUTE],[http://__HREF([$1],__DOC__)])dnl

#
# CSS_REMAP_URLS(CSS-TEXT, CSS-SRC-DIR) MACRO
# rewrites every url("...")/url(...) path in CSS-TEXT -- each interpreted
# relative to CSS-SRC-DIR -- to a path relative to __TDIR__ via __HREF,
# preserving whichever quote style (or lack of one) the source used.
# CSS-TEXT should be read as plain text (e.g. m4_esyscmd_s([cat FILE])),
# not m4_include'd, since third-party CSS isn't safe to parse as m4.
# Two passes (quoted urls, then bare urls) so the "?"-free regexes stay
# within GNU m4's regex dialect; m4_dquote re-quotes the first pass's
# result so commas in the rewritten CSS don't get mistaken for argument
# separators by the second pass.
#
m4_define([__CSS_REMAP_URLS],[dnl
m4_unquote(m4_bpatsubst(m4_dquote(m4_bpatsubst([$1],[url("\([^"]*\)")],[url("__HREF([$2/\1])")])),dnl
[url(\([^"')]*\))],[url(__HREF([$2/\1]))]))])

dnl[m4_divert_text([PAPER],[<!-- __file__ __line__ --$1-- -->])[]

m4_define([__FNAME],
[m4_bregexp($1,[\([^/]+\..+\)$], [\1])])

m4_define([__RDATE],
[m4_esyscmd_s(date --reference=$1 +%Y-%m-%d)])

dnl
dnl LOCALIZE_*(DOMAIN,LANG,STEM) MACROS
dnl
m4_define([__LOCALIZE_URL_NAME],[$2-$3])
m4_define([__LOCALIZE_URL_PATH],[$1/$2/$3])
m4_define([__LOCALIZE_URL_NULL],[$1/$3])
m4_define([__LOCALIZE_URL_DOMAIN],[$2.$1/$3])

dnl
dnl WITH_LAYOUT(LAYOUT,BODY) MACRO
dnl $1 path to an alternate layout file -- required. If a page doesn't need
dnl    a layout other than configure.m4's default __LAYOUT__, it should not
dnl    call this macro at all.
dnl $2 body to expand under the alternate __LAYOUT__
dnl
m4_define([__WITH_LAYOUT],[dnl
m4_if([$1],[],[m4_fatal([__WITH_LAYOUT requires a non-empty LAYOUT argument])])dnl
m4_define([__LAYOUT__],$1)dnl
$2dnl
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

dnl
dnl CP_ASSET(FILE) MACRO
dnl 
m4_define([__CP_ASSET],[
m4_divert_push([MAKEFILE])
m4_text_box($1 CP ASSET BEGINS,[+])
__DOC__/__DOMAIN__/$1 : __SRC__/$1
clean-asset :: ; -rm -f __DOC__/__DOMAIN__/$1 
__DOC__/__PATH_STEM__.html : __DOC__/__DOMAIN__/$1
m4_text_box($1 CP ASSET ENDS  ,[-])
m4_divert_pop([MAKEFILE])dnl
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
m4_pushdef([__PATH_STEM__],$1(__DOMAIN__,__L__,__STEM__))
dnl TODO rewiew next 2 lines
dnl m4_set_add([__CURRENT_BUILD_TARGETS__],__DOC__/__PATH_STEM__.html)dnl
dnl the nex declaration of alternates is the earliest one, in MAKEFILE PHASE
m4_set_add([__ALTERNATES__],m4_quote(__LANG__,__DOC__/__DOMAIN__,__DOC__/__PATH_STEM__.html))dnl
m4_set_add([__BUILD_TARGETS__],m4_quote(__DOC__/__DOMAIN__,__DOC__/__PATH_STEM__.html))dnl
dnl
m4_divert_push([MAKEFILE])
m4_text_box(__STEM__ MAKEFILE BEGINS (__LANG__),[+])
[#] NAVIGATION
__NAV__/__PATH_STEM__.m4 : __SRC__/generator.m4
__NAV__/__PATH_STEM__.m4 : EXTRA_NAV_FLAGS+= -D [__LANG__]=__LANG__ -D [__STEM__]=__STEM__ -D [__LOCAL_URL_ID__]=__LOCAL_URL_ID__ 
__NAV__/__PATH_STEM__.m4 : __FIRST__ | $$(@D)/ ; [$(do-generate-navigation)]
clean-navigation :: ; -rm -f __NAV__/__PATH_STEM__.m4
__NAV__/__DOMAIN__/NAVIGATION.m4 : __NAV__/__PATH_STEM__.m4
clean-navigation :: ; -rm -f __NAV__/__DOMAIN__/NAVIGATION.m4
dnl
[#] HTML 
dnl TODO: is VENDOR really needed in this PHASE?
[#] __DOC__/__PATH_STEM__.html : __NAV__/__DOMAIN__/NAVIGATION.m4
__DOC__/__PATH_STEM__.html : __LAYOUT__
__DOC__/__PATH_STEM__.html : __SRC__/generator.m4
__DOC__/__PATH_STEM__.html : EXTRA_HTML_FLAGS+= -D [__LAYOUT__]=__LAYOUT__ -D [__DOMAIN__]=__DOMAIN__ -D [__LANG__]=__LANG__ -D [__STEM__]=__STEM__ -D [__LOCAL_URL_ID__]=__LOCAL_URL_ID__ -D [__ROOT__]=__DOC__/__DOMAIN__ -D [__VENDOR__]=__VENDOR__ -D [__NAV__]=__NAV__   
__DOC__/__PATH_STEM__.html : __FIRST__ | $$(@D)/ __NAV__/__DOMAIN__/NAVIGATION.m4 ; [$(do-generate-html)]
clean-build :: ; -rm -f __DOC__/__PATH_STEM__.html
dnl
[#] DEFERRED MAKEFILE
__DOC__/__PATH_STEM__.mk : __SRC__/generator.m4
__DOC__/__PATH_STEM__.mk : EXTRA_DEFERRED_MK_FLAGS+=  -D [__LAYOUT__]=__LAYOUT__ -D [__DOMAIN__]=__DOMAIN__ -D [__LANG__]=__LANG__ -D [__STEM__]=__STEM__ -D [__LOCAL_URL_ID__]=__LOCAL_URL_ID__ -D [__ROOT__]=__DOC__/__DOMAIN__ -D [__VENDOR__]=__VENDOR__ -D [__NAV__]=__NAV__   
__DOC__/__PATH_STEM__.mk : __FIRST__ | $$(@D)/ __NAV__/__DOMAIN__/NAVIGATION.m4 ; [$(do-generate-deferred-mk)]
clean-makefile :: ; -rm -f __DOC__/__PATH_STEM__.mk
[#] -include __DOC__/__PATH_STEM__.mk
cp-deferred-asset :: | __DOC__/__PATH_STEM__.mk ; $(MAKE) --no-print-directory -f Rules.mk -f __DOC__/__PATH_STEM__.mk [__SRC__]=__SRC__ [$]@
clean-asset gzip-asset :: | __DOC__/__PATH_STEM__.mk ; $(MAKE) --no-print-directory -f Rules.mk -f __DOC__/__PATH_STEM__.mk [__SRC__]=__SRC__ [$]@
dnl
[#] ZIP
.SECONDARY : __ZIP__/__PATH_STEM__.html
__ZIP__/__PATH_STEM__.html : GZIP_EXTRA_FLAGS:= 
__ZIP__/__PATH_STEM__.html : __DOC__/__PATH_STEM__.html | $$(@D)/ __DOC__/__PATH_STEM__.mk ;  [$(do-gzip)]
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
build-__DOMAIN__ : __DOC__/__PATH_STEM__.html cp-deferred-asset | __DOC__/__PATH_STEM__.mk
.PHONY : __DOMAIN__
__DOMAIN__ : __PATH_STEM__.html
publish : __DOMAIN__
m4_popdef([__DOMAIN__])dnl
dnl 
build : __DOC__/__PATH_STEM__.html
clean-makefile :: ; [$(RM)] -f __TARGET__
m4_text_box(__STEM__ MAKEFILE ENDS  (__LANG__) ,[-])
m4_divert_pop([MAKEFILE])
dnl
m4_divert_push([NAVIGATION])dnl
m4_text_box(__PATH_STEM__,[-])
[m4_define](m4_dquote(__LOCAL_URL_ID__),m4_dquote(__DOC__/__PATH_STEM__.html))
dnl [m4_set_add](m4_quote(__UP(__[]__STEM__[]_ALTERNATES__),m4_dquote(m4_dquote(__LANG__,__LOCAL_URL_ID__))))
m4_divert_pop([NAVIGATION])
dnl
$2dnl
dnl
m4_popdef([__PATH_STEM__])
m4_popdef([__LOCAL_URL_ID__])
])

dnl
dnl ASSET MACRO
dnl $1 source relative asset URI
dnl
m4_define([__ASSET],[__HREF([__DOC__/$1])[]dnl
m4_divert_push([MAKEFILE])
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
m4_divert_pop([MAKEFILE])dnl
])

dnl
dnl ASSET3(ASSET,ROOT,TARGET)
dnl
m4_define([__ASSET3],[dnl
m4_pushdef([__ROOT__],m4_default([$2],__ROOT__))[]dnl
__HREF([__ROOT__/$1])[]dnl
m4_divert_push([MAKEFILE])
m4_text_box($1 ASSET3 BEGINS,[+])
dnl TODO next loop copies the asset files in all domains not in the ones that
dnl actually has a dependency whit it, this is an error.
__ROOT__/$1 : __SRC__/$1
clean-asset :: ; -rm -f __ROOT__/$1
dnl
$3 : __ROOT__/$1 
m4_text_box($1 ASSET3 ENDS  ,[-])
m4_divert_pop([MAKEFILE])dnl
m4_popdef([__ROOT__])dnl
])

dnl
dnl DEFERRED_ASSET2(ASSET,ROOT,TARGET)
dnl
m4_define([__DEFERRED_ASSET2],[dnl
m4_pushdef([__ROOT__],m4_default([$2],__ROOT__))[]dnl
__HREF([__ROOT__/$1])[]dnl
m4_divert_push([DEFERRED_MK])
m4_text_box($1 DEFERRED_ASSET3 BEGINS,[+])
__ROOT__/$1 : __SRC__/$1 | [$$](@D)/ ; cp [$]< [$]@
cp-deferred-asset : __ROOT__/$1 
clean-asset :: ; -rm -f __ROOT__/$1
m4_text_box($1 DEFERRED_ASSET3 ENDS  ,[-])
m4_divert_pop([DEFERRED_MK])dnl
m4_popdef([__ROOT__])dnl
])


dnl
dnl INCL() MACRO
dnl source relative filename
dnl
m4_define([__INCL],[dnl
m4_divert_text([MAKEFILE],[
m4_text_box($1 INCLUDE BEGINS,[+])
m4_set_foreach([__BUILD_TARGETS__],[__I__],[dnl
m4_unquote(m4_cdr(__I__)) : $1
])dnl
m4_text_box($1 INCLUDE ENDS  ,[-])
])[]m4_include([$1])])

dnl
dnl NAV_ITEM(TEXT,URL,FRAGMENT)
dnl
m4_define([__NAV_ITEM],[dnl
m4_divert_text([NAVIGATION],m4_dquote([m4_set_add](m4_dquote(__NAV__ITEMS__),m4_dquote(m4_dquote(__LANG__,$2,$3,$4)))))dnl
$2[]dnl
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
m4_include([./configure.m4])dnl
dnl
dnl HERE WE FILL THE DIVERSIONS
dnl
m4_if(__PHASE__,[GENERATE_HTML_PHASE],[m4_include(__NAV__/__DOMAIN__/NAVIGATION.m4)],__PHASE__,[GENERATE_DEFERRED_MK_PHASE],[m4_include(__NAV__/__DOMAIN__/NAVIGATION.m4)],[])dnl
dnl m4_sinclude(__NAV__/__DOMAIN__/NAVIGATION)
m4_include(__FIRST__)dnl
dnl
dnl NOW THE LAYOUT CONSUME THE DIVERSIONS
dnl
m4_include(__LAYOUT__)dnl
dnl
dnl AND CHOOSE WHAT TO EMIT INTO DEFAULT
dnl
m4_case(__PHASE__,
[GENERATE_MAKEFILE_PHASE],[m4_divert_text([DEFAULT],[m4_undivert([MAKEFILE])])],
[GENERATE_NAVIGATION_PHASE],[m4_divert_text([DEFAULT],[m4_undivert([NAVIGATION])])],
[GENERATE_HTML_PHASE],[m4_divert_text([DEFAULT],[m4_undivert([HTML])])],
[GENERATE_DEFERRED_MK_PHASE],[m4_divert_text([DEFAULT],[m4_undivert([DEFERRED_MK])])],
[MAKEPUB_PHASE],[m4_divert_text([DEFAULT],[m4_undivert([PUBLISH])])],

[TEST_PHASE],[m4_divert_text([DEFAULT],[m4_undivert([TESTS])])],

[m4_fatal(Unmached! [__PHASE__]==__PHASE__)])
dnl DISCARD ALL OFF-PHASE TEXT
m4_cleardivert([MAKEFILE])
m4_cleardivert([DEFERRED_MK])
dnl m4_cleardivert([SITEMAP])
m4_cleardivert([HEAD])
m4_cleardivert([MAIN])
m4_cleardivert([CUSTOM_STYLES])
m4_cleardivert([CUSTOM_ELEMENTS])
m4_cleardivert([NAVIGATION])
m4_cleardivert([HTML])
m4_cleardivert([EPILOG])