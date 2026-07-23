# Include the file to be tested
m4_include([generator.m4])dnl

#
# ASSERT_EQ(NAME, ACTUAL, EXPECTED) -- self-checking test helper.
# pass ACTUAL as a macro call (unquoted) so it is expanded before
# comparison; prints PASS/FAIL so `make test` can grep for FAIL.
#
m4_define([__ASSERT_EQ],[m4_if([$2],[$3],[PASS $1],[FAIL $1: got [$2] expected [$3]])])

#
# __FNAME extracts the bare filename (last path component) from a path,
# via m4_bregexp's [^/]+\..+ pattern anchored at end of string -- stripping
# any leading directories regardless of how many levels deep.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([FNAME no directory],__FNAME([index.html]),[index.html])
__ASSERT_EQ([FNAME one directory],__FNAME([en/about.html]),[about.html])
__ASSERT_EQ([FNAME nested directories],__FNAME([en/en/about.html]),[about.html])
m4_divert_pop([TESTS])dnl


#
# __HREF computes a relative path between two locations (via `realpath
# --relative-to`), independent of the current working directory.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([HREF relative to base],__HREF([/tmp/bucket/es/about.html],[/tmp/bucket/en]),[../es/about.html])
m4_divert_pop([TESTS])dnl


#
# __HREF([./img/logo.png]) depends on the build's PWD (relative to __TDIR__),
# kept for manual inspection only -- intentionally left outside any TESTS
# push, so it (and this comment) land in KILL and never appear in
# `make test` output:
#
|__HREF([./img/logo.png])|


#
# __TDIR__ is /tmp/test during `make test` (see Makefile); __CSS_REMAP_URLS
# rewrites url(...) paths relative to /tmp/test/vendor/css to be relative
# to /tmp/test instead.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([CSS_REMAP_URLS quoted url],dnl
__CSS_REMAP_URLS([@font-face{src:url("../webfonts/a.woff2") format("woff2")}],[/tmp/test/vendor/css]),dnl
[@font-face{src:url("vendor/webfonts/a.woff2") format("woff2")}])
__ASSERT_EQ([CSS_REMAP_URLS bare url],dnl
__CSS_REMAP_URLS([@font-face{src:url(../webfonts/b.eot)}],[/tmp/test/vendor/css]),dnl
[@font-face{src:url(vendor/webfonts/b.eot)}])
__ASSERT_EQ([CSS_REMAP_URLS mixed quoted and bare urls],dnl
__CSS_REMAP_URLS([url("../webfonts/a.woff2");url(../webfonts/b.eot)],[/tmp/test/vendor/css]),dnl
[url("vendor/webfonts/a.woff2");url(vendor/webfonts/b.eot)])
m4_divert_pop([TESTS])dnl


#
# __ABSOLUTE turns a __BUILD_ROOT__/DOC-relative path into a http://host/path URL,
# treating the first path segment (relative to __BUILD_ROOT__/DOC) as the host.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([ABSOLUTE nested path],__ABSOLUTE([__BUILD_ROOT__/DOC/tests.com/en/about.html]),[http://tests.com/en/about.html])
__ASSERT_EQ([ABSOLUTE single segment path],__ABSOLUTE([__BUILD_ROOT__/DOC/tests.com/about.html]),[http://tests.com/about.html])
__ASSERT_EQ([ABSOLUTE doc root],__ABSOLUTE([__BUILD_ROOT__/DOC/index.html]),[http://index.html])
m4_divert_pop([TESTS])dnl

#
# __NAV_TARGET_DOMAIN__ extracts a nav URL's domain -- the first path segment
# of the URL taken relative to __BUILD_ROOT__/DOC. This is what __NAV_HREF
# compares against __DOMAIN__ to route cross-domain nav links through
# __ABSOLUTE. Derived independently: the segment after DOC/ is the domain.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([NAV_TARGET_DOMAIN first path segment],__NAV_TARGET_DOMAIN__([__BUILD_ROOT__/DOC/tekii.llc/index.html]),[tekii.llc])
m4_divert_pop([TESTS])dnl

#
# __UP translits "." to "_" and upcases -- used to build domain-derived macro
# names (__LANDING_<DOMAIN>_URL__, __LOCAL_URL_ID__). Pinned in isolation:
# "tekii.com.ar" upcased with dots as underscores is TEKII_COM_AR (derived by
# hand from the translit spec, not the macro's output).
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([UP dots-to-underscores and upcase],__UP([tekii.com.ar]),[TEKII_COM_AR])
m4_divert_pop([TESTS])dnl


#
# The firebase.json hosting entry is now emitted by the file-scope template
# firebase-entry.json.m4 (the meta.json guillemet idiom, m4_include'd into the
# PUBLISH diversion), not by a macro -- so it is proven at artifact level
# (fragment bytes + firebase.json validity in the verification), not through
# __ASSERT_EQ argument collection. What stays unit-testable is the single
# transformation the template depends on: the site ID is __DOMAIN__ with a
# literal -teppan-site suffix, every dot dashed. Derived by hand:
# tekii.com.ar-teppan-site -> tekii-com-ar-teppan-site (the suffix has no dot,
# so substitution leaves it intact). This must match the Makefile's per-domain
# --only hosting:<id>-teppan-site.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([firebase entry site id: dashed domain plus -teppan-site suffix],m4_bpatsubst([tekii.com.ar-teppan-site],[\.],[-]),[tekii-com-ar-teppan-site])
m4_divert_pop([TESTS])dnl


#
# __AS_REDIRECT_DOMAINS(DOMAINS,BODY) pushdefs __REDIRECT_DOMAINS_CONTEXT__ to
# DOMAINS around BODY's expansion -- visible inside BODY, popped once the macro
# returns. Same dynamic-scope shape as the __AS_LANDING context check above.
# m4_quote wraps the call so the comma in the multi-domain DOMAINS value stays
# one argument to __ASSERT_EQ instead of splitting it.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([AS_REDIRECT_DOMAINS context visible in body],dnl
m4_quote(__AS_REDIRECT_DOMAINS([a.x,b.y],[m4_ifdef([__REDIRECT_DOMAINS_CONTEXT__],[__REDIRECT_DOMAINS_CONTEXT__],[UNSET])])),[a.x,b.y])
__ASSERT_EQ([AS_REDIRECT_DOMAINS context not visible after],dnl
m4_ifdef([__REDIRECT_DOMAINS_CONTEXT__],[SET],[UNSET]),[UNSET])
m4_divert_pop([TESTS])dnl


#
# __WITH_LAYOUT's extra positional args (after the mandatory LAYOUT,BODY)
# must be visible -- as __LAYOUT_EXTRA_ARGN__/__LAYOUT_EXTRA_ARGC__ -- by
# the time BODY expands, since that's where a page source nests its
# __MAKE_PAGE call. Assert from inside BODY itself (not just after the
# call returns) so the test actually pins body-time visibility rather
# than only the chosen persist-after-call lifetime.
# the embedded newline before the closing bracket is required: $2dnl in
# __WITH_LAYOUT's own definition directly concatenates onto $2's expanded
# text with no separator, so a body expanding to plain text ending in a
# word character (our PASS/FAIL message) would otherwise fuse with the
# literal "dnl" into one unrecognized token instead of two.
#
m4_divert_push([TESTS])dnl
__WITH_LAYOUT([dummy-layout.html],dnl
[__ASSERT_EQ([WITH_LAYOUT extra arg visible in body],__LAYOUT_EXTRA_ARG1__,[first])
],dnl
[first],[second])dnl
__ASSERT_EQ([WITH_LAYOUT extra arg 1],__LAYOUT_EXTRA_ARG1__,[first])
__ASSERT_EQ([WITH_LAYOUT extra arg 2],__LAYOUT_EXTRA_ARG2__,[second])
__ASSERT_EQ([WITH_LAYOUT extra arg count],__LAYOUT_EXTRA_ARGC__,[2])
m4_divert_pop([TESTS])dnl


#
# __AS_LANDING(BODY) pushdefs __LANDING_CONTEXT__ around BODY's expansion --
# visible to whatever BODY contains (e.g. a nested __MAKE_PAGE call), gone
# once __AS_LANDING returns. Assert both sides directly, same shape as the
# WITH_LAYOUT extra-arg visibility check above.
#
m4_divert_push([TESTS])dnl
__AS_LANDING([dnl
__ASSERT_EQ([AS_LANDING context visible in body],dnl
m4_ifdef([__LANDING_CONTEXT__],[yes],[no]),[yes])
])dnl
__ASSERT_EQ([AS_LANDING context not visible after],dnl
m4_ifdef([__LANDING_CONTEXT__],[yes],[no]),[no])
m4_divert_pop([TESTS])dnl


#
# __LANG_NAME looks up a language's display name from __LANGS__ by its
# internal code, returning "UNDEFINED LANG" for unknown/short argument lists.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([LANG_NAME en],__LANG_NAME([en]),[English])
__ASSERT_EQ([LANG_NAME es],__LANG_NAME([es]),[Español])
__ASSERT_EQ([LANG_NAME br],__LANG_NAME([br]),[Português])
__ASSERT_EQ([LANG_NAME unknown],__LANG_NAME([nn]),[UNDEFINED LANG])
__ASSERT_EQ([LOOKUP_LANG_NAME 2-arg],__LOOKUP_LANG_NAME([xx],[yy]),[UNDEFINED LANG])
m4_divert_pop([TESTS])dnl


#
# __LANG_FLAG maps an internal code to its region flag stem (garnish only):
# es->AR, en->US, br->BR; unknown codes fall through to "UNDEFINED LANG" like
# the other __LOOKUP_LANG_NAME-based maps. EXPECTED derived from the mapping
# spec, not the macro's output.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([LANG_FLAG en maps to US],__LANG_FLAG([en]),[US])
__ASSERT_EQ([LANG_FLAG es maps to AR],__LANG_FLAG([es]),[AR])
__ASSERT_EQ([LANG_FLAG br maps to BR],__LANG_FLAG([br]),[BR])
__ASSERT_EQ([LANG_FLAG unknown],__LANG_FLAG([nn]),[UNDEFINED LANG])
m4_divert_pop([TESTS])dnl


#
# __LANG_NAME__ is defined as m4_define([__LANG_NAME__], __LANG_NAME(__LANG__))
# with an UNQUOTED second argument, so it is resolved once at the point
# generator.m4 is m4_include'd here -- NOT dynamically per m4_pushdef([__LANG__],...).
# Since generator_test.m4 never -D's __LANG__, it is literally "__LANG__" (undefined)
# at that point, so __LANG_NAME__ is frozen to "UNDEFINED LANG" for this whole file,
# regardless of any later pushdef.
#
m4_divert_push([TESTS])dnl
m4_pushdef([__LANG__],[es])dnl
__ASSERT_EQ([LANG_NAME__ ignores later pushdef],__LANG_NAME__,[UNDEFINED LANG])
m4_popdef([__LANG__])dnl
m4_divert_pop([TESTS])dnl


#
# __ESEN(SPANISH,ENGLISH) / __ENES(ENGLISH,SPANISH) pick a branch based on
# __LANG__ at call time (their bodies are quoted m4_case(__LANG__,...)
# calls, re-evaluated per call, not frozen at m4_include time).
#
m4_divert_push([TESTS])dnl
m4_pushdef([__LANG__],[es])dnl
__ASSERT_EQ([ESEN under es],__ESEN([Hola],[Hello]),[Hola])
__ASSERT_EQ([ENES under es],__ENES([Hello],[Hola]),[Hola])
m4_popdef([__LANG__])dnl
m4_divert_pop([TESTS])dnl


#
# same ESEN/ENES check as above, with __LANG__ pushed to __EN__ instead --
# confirms the other branch of both macros also resolves correctly.
#
m4_divert_push([TESTS])dnl
m4_pushdef([__LANG__],[en])dnl
__ASSERT_EQ([ESEN under en],__ESEN([Hola],[Hello]),[Hello])
__ASSERT_EQ([ENES under en],__ENES([Hello],[Hola]),[Hello])
m4_popdef([__LANG__])dnl
m4_divert_pop([TESTS])dnl


#
# __RDATE(FILE) shells out to `date --reference=FILE +%Y-%m-%d` and chomps
# the trailing newline. Fix the reference file's mtime so the expected
# date is independent of when the test happens to run.
#
m4_divert_push([TESTS])dnl
m4_esyscmd([touch -d 2020-03-04 /tmp/__rdate_test_file])dnl
__ASSERT_EQ([RDATE fixed mtime],__RDATE([/tmp/__rdate_test_file]),[2020-03-04])
m4_divert_pop([TESTS])dnl

#
# __LOCALIZE_URL_SUBDOMAIN(DOMAIN,LANG,STEM) prepends LANG as a subdomain
# label ahead of DOMAIN, rather than using it as a path segment the way
# __LOCALIZE_URL_PATH does.
#
m4_divert_push([TESTS])dnl
__ASSERT_EQ([LOCALIZE_URL_SUBDOMAIN prepends lang as subdomain],__LOCALIZE_URL_SUBDOMAIN([example.com],[en],[about]),[en.example.com/about])
m4_divert_pop([TESTS])dnl


#
# LEGACY -- exploratory/scratch m4sugar experiments kept for historical
# reference, not real tests. Left unwrapped (outside any TESTS push) so
# their output lands in KILL and never appears in `make test`.
#
#m4_changequote(`«', `»')#m4_fatal(«bye»)
dnl m4_translit(«a.html b.html   c/d.html»,« »,«,»)
dnl m4_patsubst(«a.html b.html   c/d.html»,«\ +»,«,»)
dnl m4_syscmd(«date --reference=index.html +%Y-%m-%d»)

#m4_esyscmd(relpath  __ROOT__ __BASE__)

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
dnl m4_bregexp([m4_include(_build/vendor/fontawesome-free-5.13.0-web/css/all.css)],[url\($1\)],[\1])
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



