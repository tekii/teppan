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

__ASSERT_EQ([ABSOLUTE nested path],__ABSOLUTE([__DOC__/tests.com/en/about.html]),[http://tests.com/en/about.html])
__ASSERT_EQ([ABSOLUTE single segment path],__ABSOLUTE([__DOC__/tests.com/about.html]),[http://tests.com/about.html])
__ASSERT_EQ([ABSOLUTE doc root],__ABSOLUTE([__DOC__/index.html]),[http://index.html])


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


m4_define([__L],
[m4_if([$#], 0, [m4_fatal([$0: cannot be called without arguments]],
       [$#], 1, [m4_fatal([$0: cannot be called with 1 arguments])],
       [$#], 2, [UNDEFINED LANG],
       [m4_if($1,$2,$3,[__L($1,m4_shift(m4_shift(m4_shift($@))))])])])


dnl m4_traceon([__LANG_NAME3])
---------------------------------------
dnl >>>>>__LOOKUP_LANG_NAME(en,m4_unquote(__LANGS__))<<<<<
dnl >>>>>__LOOKUP_LANG_NAME(es,m4_unquote(__LANGS__))<<<<<
dnl >>>>>__LOOKUP_LANG_NAME(pt,m4_unquote(__LANGS__))<<<<<
dnl >>>>>__LOOKUP_LANG_NAME(nn,m4_unquote(__LANGS__))<<<<<
dnl >>>>>__LANG_NAME(en)<<<<<
dnl >>>>>__LOOKUP_LANG_NAME(nn)<<<<<
---------------------------------------
dnl m4_traceoff([__LANG_NAME3])dnl
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



