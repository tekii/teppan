dnl Include the file to be tested
dnl
m4_include([generator.m4])dnl
dnl Set the TESTS out divert
m4_divert([TESTS])dnl

dnl
dnl ASSERT_EQ(NAME, ACTUAL, EXPECTED) -- self-checking test helper.
dnl pass ACTUAL as a macro call (unquoted) so it is expanded before
dnl comparison; prints PASS/FAIL so `make test` can grep for FAIL.
dnl
m4_define([__ASSERT_EQ],[m4_if([$2],[$3],[PASS $1],[FAIL $1: got [$2] expected [$3]])])

#m4_changequote(`«', `»')#m4_fatal(«bye»)
dnlm4_translit(«a.html b.html   c/d.html»,« »,«,»)
dnlm4_patsubst(«a.html b.html   c/d.html»,«\ +»,«,»)
dnlm4_syscmd(«date --reference=index.html +%Y-%m-%d»)

#m4_esyscmd(relpath  __ROOT__ __BASE__)


m4_bregexp([index.html],       [\([^/]+\..+\)$], [\1])
m4_bregexp([en/about.html],    [\([^/]+\..+\)$], [\1])
m4_bregexp([en/en/about.html], [\([^/]+\..+\)$], [\1])

__ASSERT_EQ([HREF relative to base],__HREF([/tmp/bucket/es/about.html],[/tmp/bucket/en]),[../es/about.html])
dnl __HREF([./img/logo.png]) depends on the build's PWD (relative to __TDIR__), kept for manual inspection only:
|__HREF([./img/logo.png])|

dnl __TDIR__ is /tmp/test during `make test` (see Makefile); __CSS_REMAP_URLS
dnl rewrites url(...) paths relative to /tmp/test/vendor/css to be relative
dnl to /tmp/test instead.
__ASSERT_EQ([CSS_REMAP_URLS quoted url],dnl
__CSS_REMAP_URLS([@font-face{src:url("../webfonts/a.woff2") format("woff2")}],[/tmp/test/vendor/css]),dnl
[@font-face{src:url("vendor/webfonts/a.woff2") format("woff2")}])

__ASSERT_EQ([CSS_REMAP_URLS bare url],dnl
__CSS_REMAP_URLS([@font-face{src:url(../webfonts/b.eot)}],[/tmp/test/vendor/css]),dnl
[@font-face{src:url(vendor/webfonts/b.eot)}])

__ASSERT_EQ([CSS_REMAP_URLS mixed quoted and bare urls],dnl
__CSS_REMAP_URLS([url("../webfonts/a.woff2");url(../webfonts/b.eot)],[/tmp/test/vendor/css]),dnl
[url("vendor/webfonts/a.woff2");url(vendor/webfonts/b.eot)])

__ASSERT_EQ([ABSOLUTE nested path],__ABSOLUTE([__DOC__/tests.com/en/about.html]),[http://tests.com/en/about.html])
__ASSERT_EQ([ABSOLUTE single segment path],__ABSOLUTE([__DOC__/tests.com/about.html]),[http://tests.com/about.html])
__ASSERT_EQ([ABSOLUTE doc root],__ABSOLUTE([__DOC__/index.html]),[http://index.html])

dnl __WITH_LAYOUT's extra positional args (after the mandatory LAYOUT,BODY)
dnl must be visible -- as __LAYOUT_EXTRA_ARGN__/__LAYOUT_EXTRA_ARGC__ -- by
dnl the time BODY expands, since that's where a page source nests its
dnl __MAKE_PAGE call. Assert from inside BODY itself (not just after the
dnl call returns) so the test actually pins body-time visibility rather
dnl than only the chosen persist-after-call lifetime.
dnl the embedded newline before the closing bracket is required: $2dnl in
dnl __WITH_LAYOUT's own definition directly concatenates onto $2's expanded
dnl text with no separator, so a body expanding to plain text ending in a
dnl word character (our PASS/FAIL message) would otherwise fuse with the
dnl literal "dnl" into one unrecognized token instead of two.
__WITH_LAYOUT([dummy-layout.html],dnl
[__ASSERT_EQ([WITH_LAYOUT extra arg visible in body],__LAYOUT_EXTRA_ARG1__,[first])
],dnl
[first],[second])dnl
__ASSERT_EQ([WITH_LAYOUT extra arg 1],__LAYOUT_EXTRA_ARG1__,[first])
__ASSERT_EQ([WITH_LAYOUT extra arg 2],__LAYOUT_EXTRA_ARG2__,[second])
__ASSERT_EQ([WITH_LAYOUT extra arg count],__LAYOUT_EXTRA_ARGC__,[2])

__ASSERT_EQ([LANG_NAME en],__LANG_NAME([en]),[English])
__ASSERT_EQ([LANG_NAME es],__LANG_NAME([es]),[Español])
__ASSERT_EQ([LANG_NAME br],__LANG_NAME([br]),[Português])
__ASSERT_EQ([LANG_NAME unknown],__LANG_NAME([nn]),[UNDEFINED LANG])
__ASSERT_EQ([LOOKUP_LANG_NAME 2-arg],__LOOKUP_LANG_NAME([xx],[yy]),[UNDEFINED LANG])

dnl __LANG_NAME__ is defined as m4_define([__LANG_NAME__], __LANG_NAME(__LANG__))
dnl with an UNQUOTED second argument, so it is resolved once at the point
dnl generator.m4 is m4_include'd here -- NOT dynamically per m4_pushdef([__LANG__],...).
dnl Since generator_test.m4 never -D's __LANG__, it is literally "__LANG__" (undefined)
dnl at that point, so __LANG_NAME__ is frozen to "UNDEFINED LANG" for this whole file,
dnl regardless of any later pushdef.
m4_pushdef([__LANG__],[es])dnl
__ASSERT_EQ([LANG_NAME__ ignores later pushdef],__LANG_NAME__,[UNDEFINED LANG])
m4_popdef([__LANG__])dnl

dnl __ESEN(SPANISH,ENGLISH) / __ENES(ENGLISH,SPANISH) pick a branch based on
dnl __LANG__ at call time (their bodies are quoted m4_case(__LANG__,...)
dnl calls, re-evaluated per call, not frozen at m4_include time).
m4_pushdef([__LANG__],[es])dnl
__ASSERT_EQ([ESEN under es],__ESEN([Hola],[Hello]),[Hola])
__ASSERT_EQ([ENES under es],__ENES([Hello],[Hola]),[Hola])
m4_popdef([__LANG__])dnl

m4_pushdef([__LANG__],[en])dnl
__ASSERT_EQ([ESEN under en],__ESEN([Hola],[Hello]),[Hello])
__ASSERT_EQ([ENES under en],__ENES([Hello],[Hola]),[Hello])
m4_popdef([__LANG__])dnl

dnl __RDATE(FILE) shells out to `date --reference=FILE +%Y-%m-%d` and chomps
dnl the trailing newline. Fix the reference file's mtime so the expected
dnl date is independent of when the test happens to run.
m4_esyscmd([touch -d 2020-03-04 /tmp/__rdate_test_file])dnl
__ASSERT_EQ([RDATE fixed mtime],__RDATE([/tmp/__rdate_test_file]),[2020-03-04])


m4_foreach_w([__X__], m4_unquote([__LIST__]), [==__X__==])



m4_define([m4_foreach_lang],
[m4_if([$2], [], [],
       [m4_pushdef([$1])_m4_foreach([m4_define([$1],], [)$3], [],
  $2)m4_popdef([$1])])])

m4_define([TEST],[------$1---$2---])

m4_define([m4_foreach_xxx],
        [m4_foreach(
                [Iter],
                [[__EN__,[Enghish]],[__ES__,[Español]]],
                [m4_pushdef([$1])m4_pushdef([$2])m4_define([$1],m4_car(Iter))m4_define([$2],m4_cdr(Iter))$3[]m4_popdef([$2])m4_popdef([$1])])])




---------------------------------------------------
#m4_traceon([_m4_foreach_xxx])
#m4_foreach_xxx(
#        [__L__],[__N__],
#        [
#     -__L__=__N__-])
#m4_traceoff([m4_foreach_xxx])

#m4_cleardivert([DEFAULT])dnl
#m4_divert([DEFAULT])dnl


dnl m4_traceon([__PAGE])dnl
dnl m4_traceon([__LOCALIZE_URL_NAME])dnl
dnl m4_traceon([__LOCALIZE_URL_PATH])dnl
dnl m4_traceon([__LOCALIZE_URL_NULL])dnl
---------------------------------------
dnl __PAGE([aaa.com],[en,es],[somepath/main],[__CANONICAL_PAGE__],[__LOCALIZE_URL_PATH])
dnl __PAGE([bbb.com],[en],   [somepath/main],[__ALTERNATE_PAGE__],[__LOCALIZE_URL_PATH])
---------------------------------------
dnl m4_traceoff([__LOCALIZE_URL_NULL])dnl
dnl m4_traceoff([__LOCALIZE_URL_NAME])dnl
dnl m4_traceoff([__PAGE])dnl
MAKEFILE---------------------------------
m4_undivert([MAKEFILE])dnl
MAKEFILE---------------------------------
NAVIGATION-----------------------------
m4_undivert([NAVIGATION])dnl
NAVIGATION-----------------------------

INC_CSS--------------------------------
dnl m4_changequote(«,»)
dnl m4_bregexp([m4_include(/home/rodablo/www/_build/vendor/fontawesome-free-5.13.0-web/css/all.css)],[url\($1\)],[\1])
dnl m4_bregexp([jsflkfjdlskjfurl("roro")sjdlurl("tata")fkjslkdfj],[\(url("\(.+\)")\)],[\1])
dnl m4_changequote([,])
dnl m4_define([__TOTO__],m4_flatten(m4_esyscmd_s([grep -oP '(?<=url\(\").+?(?=\"\))' _build/vendor/fontawesome-free-5.13.0-web/css/all.css])))
dnl INC_CSS--------------------------------
dnl >__TOTO__<
dnl INC_CSS--------------------------------
dnl m4_foreach_w([__L__],[__TOTO__],m4_quote([__L__]))
dnl INC_CSS--------------------------------
dnl m4_traceon(m4_dquote)m4_traceon(m4_dquote_elt)
--------------------------------
dnl [m4_quote(1,2,3,4,5)]
--------------------------------
dnl m4_dquote(1,2,3,4,5)
--------------------------------
dnl m4_dquote_elt(1,2,3,4,5)
dnl m4_combine([, ], [[a], [b], [c]], [-], [1], [2], [3])
dnl m4_map_args_w(esto es un string, [<], [m4_curry([m4_quote],[$1])], [sep])
dnl m4_traceon([m4_curry])
dnl m4_curry([m4_curry],[m4_curry],[m4_quote],1)(2)(3)(4)
--------------------------------
m4_define([__TESTL__],[[[a],[b],[c]],[[d],[e],[f]],[a]])
m4_define([__RENDER],[dnl
m4_pushdef([$0_T],[$2])dnl
m4_foreach([__I__],[$1],[m4_indir([$0_T],__I__)])dnl
m4_popdef([$0_T])dnl
])
dnl m4_traceon([__RENDER])
>>>__RENDER([__TESTL__],[==$1==$2==$3==$4==
])<<<
dnl _m4_foreach([m4_define([i],],[)i],[],[111111111111111],[22222222222222222])
dnl m4_map_args_sep([__RENDER(],[)],[--],__TESTL__)
--------------------------------
dnl m4_eval([==$1==$2==$3==],__TESTL__)

m4_set_add(__TEST_SET__,[[A],[B]])
m4_set_add(__TEST_SET__,[[C],[D]])
m4_set_add(__TEST_SET__,[[E],[F]])

m4_define([__RENDERS],[dnl
m4_pushdef([$0_T],[$2])dnl
m4_set_foreach([$1],[__I__],[m4_indir([$0_T],__I__)])dnl
m4_popdef([$0_T])dnl
])

>>>__RENDERS([__TEST_SET__],[**$1**$2**$3**$4**
])<<<

dnl m4_debugmode([acetl])



