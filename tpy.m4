#
# diverts
#
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
#
# constants
#
m4_define([__TEKII__],[<strong>TEKii$1</strong>])
m4_define([__TEKII_SRL_]_,__TEKII__([ SRL]))

#
# LANG conditionals
#
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
[m4_esyscmd_s(__RP__ --canonicalize-missing $1 --relative-to=m4_default([$2],[__TDIR__]))])

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
m4_define([__LOCALIZE_URL_NAME],[$1-$2])
m4_define([__LOCALIZE_URL_PATH],[$2/$1])
m4_define([__LOCALIZE_URL_NULL],[$1])

dnl
dnl PAGE MACRO
dnl $1 lang keys list
dnl $2 localization strategy
dnl $3 (optional) page key, defaults to __TNAME__
dnl
m4_define([__PAGE],[dnl
m4_foreach([__I__], [$2],[m4_pushdef([__STEM__],$3([$1],__I__))dnl
m4_set_add([__CURRENT_BUILD_TARGETS__],[__ROOT__/__STEM__.html])dnl
m4_divert_text([DEPEND],[dnl
[#] __STEM__
__ROOT__/__STEM__.html : EXTRA_BUILD_FLAGS+= -D __LANG__=__I__ -D __ALTERNATE__
__ROOT__/__STEM__.html : __FIRST__ | $$(@D)/ ; [$(do-build)]
__ROOT__/__STEM__.html : __SRC__/layout.html
__ROOT__/__STEM__.html : __SRC__/tpy.m4
build : __ROOT__/__STEM__.html
clean :: ; [$(RM)] __ROOT__/__STEM__.html
realclean :: ; [$(RM)] __TARGET__
])dnl DEPEND
m4_divert_text([NAVIGATION],[dnl
nothing to see here yet
])dnl NAVIGATION
m4_popdef([__STEM__])dnl
])dnl foreach
])dnl

dnl
dnl ASSET MACRO
dnl $1 source relative asset URI
dnl
m4_define([__ASSET],[__HREF([__ROOT__/$1])[]dnl
m4_divert_text([DEPEND],[dnl
__ROOT__/$1 : __SRC__/$1 
m4_set_foreach([__CURRENT_BUILD_TARGETS__],[__I__],[dnl
__I__ : __ROOT__/$1
])dnl
clean:: ; [$(RM)] __ROOT__/$1 
])])

dnl
dnl INCL MACRO
dnl source relative filename
dnl
m4_define([__INCL],[
m4_divert_text([DEPEND],[dnl
[# from INCL]
m4_set_foreach([__CURRENT_BUILD_TARGETS__],[__BUILD_TARGET__],[dnl
__BUILD_TARGET__ : $1
])dnl
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
[# NAVIGATION BEGIN]
__ROOT__/__STEM__.txt : __FIRST__
__ROOT__/navigation.txt : __ROOT__/__STEM__.txt
m4_set_foreach([__CURRENT_BUILD_TARGETS__],[__BUILD_TARGET__],[dnl
__BUILD_TARGET__ : __ROOT__/navigation.txt
])dnl
clean :: ; [$(RM)] __ROOT__/__STEM__.txt
clean :: ; [$(RM)] __ROOT__/navigation.txt 
[# NAVIGATION END]
])dnl
m4_if(__DO__,[MAKEBUILD],[m4_include(__ROOT__/navigation.txt)],[])dnl
])

dnl
dnl PAGE PROCESS STARTS HERE
dnl PAGE PROCESS STARTS HERE
dnl PAGE PROCESS STARTS HERE
dnl
dnl HERE WE LOAD THE DIVERSIONS
dnl
m4_include(__FIRST__)
dnl
dnl NOW THE LAYOUT CONSUME THE DIVERSIONS
dnl
m4_include(__LAYOUT__)
dnl
dnl AND FINALLY CHOOSE WHAT TO EMIT
dnl
m4_case(__DO__,
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
],
[
m4_fatal([Unmached [__DO__]:__DO__],[1])
m4_cleardivert([DEPEND])
m4_cleardivert([SITEMAP])
m4_cleardivert([HEADER])
m4_cleardivert([BODY])
m4_cleardivert([AMP_CUSTOM_STYLES])
m4_cleardivert([AMP_CUSTOM_ELEMENTS])
m4_cleardivert([NAVIGATION])
m4_cleardivert([BUILD])
m4_cleardivert([PAPER])
])
