#
# diverts
# 1 sitemap
# 2 header
# 3 body
# 5 amp custom styles
# 6 amp custom elements
#
m4_define([_m4_divert(DEFAULT)], 0)
m4_define([_m4_divert(DEPEND)], 1)
m4_define([_m4_divert(SITEMAP)], 2)
m4_define([_m4_divert(HEADER)], 3)
m4_define([_m4_divert(BODY)], 4)
m4_define([_m4_divert(AMP_CUSTOM_STYLES)], 5)
m4_define([_m4_divert(AMP_CUSTOM_ELEMENTS)], 6)
m4_define([_m4_divert(BUILD)], 7)
m4_define([_m4_divert(PAPER)], 8)
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
# calculate path jump relative to __BASE__ or $2
# TODO: strip fragments #xxx
#
m4_define([__HREF],
[m4_esyscmd_s(__RP__ --canonicalize-missing $1 --relative-to=m4_default([$2],[__BASE__]))])

dnl[m4_divert_text([PAPER],[<!-- __file__ __line__ --$1-- -->])[]

m4_define([__FNAME],
[m4_bregexp($1,[\([^/]+\..+\)$], [\1])])

m4_define([__RDATE],
[m4_chomp_all(m4_esyscmd(date --reference=$1 +%Y-%m-%d))])

#
# BUILD MACROS
#
m4_define([__BUILD_LANG],[
m4_divert_text([DEPEND],[
__ROOT__/$1/__FNAME__: EXTRA_BUILD_FLAGS+= -D __LANG__=$1 -D __ALTERNATE__
[#] __ROOT__/$1/__FNAME__: __SRC__/__FNAME__
build: __ROOT__/$1/__FNAME__
clean:: ; [$(RM)] __ROOT__/$1/__FNAME__
realclean:: ; [$(RMDIR)] __ROOT__/$1
])])

m4_define([__BUILD_TOP],[
m4_divert_text([DEPEND],[
__ROOT__/__FNAME__: EXTRA_BUILD_FLAGS+= -D __LANG__=$1
build: __ROOT__/__FNAME__
clean:: ; [$(RM)] __ROOT__/__FNAME__
])])

m4_define([__BUILD_COPY],[
m4_divert_text([DEPEND],[
__SRC__/__FNAME__ : $1
build: __ROOT__/static/$1
clean:: ; [$(RM)] __ROOT__/[$(__STATIC__)]/$1
])])

m4_define([__INCL],[
m4_divert_text([DEPEND],[
__SRC__/__FNAME__ : $1
])[]m4_include([$1])])

dnl
dnl PAGE PROCESS STARTS HERE
dnl
m4_include(__FNAME__)
dnl
dnl NOW THE LAYOUT
dnl
m4_include(layout.html)
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
m4_cleardivert([BUILD])
m4_cleardivert([PAPER])
])
