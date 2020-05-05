m4_include([generator.m4])dnl

#m4_changequote(`«', `»')#m4_fatal(«bye»)
dnlm4_translit(«a.html b.html   c/d.html»,« »,«,»)
dnlm4_patsubst(«a.html b.html   c/d.html»,«\ +»,«,»)
dnlm4_syscmd(«date --reference=index.html +%Y-%m-%d»)

#m4_esyscmd(relpath  __ROOT__ __BASE__)


m4_bregexp([index.html],       [\([^/]+\..+\)$], [\1])
m4_bregexp([en/about.html],    [\([^/]+\..+\)$], [\1])
m4_bregexp([en/en/about.html], [\([^/]+\..+\)$], [\1])

|__HREF([/tmp/bucket/es/about.html],[/tmp/bucket/en])|
|__HREF([./img/logo.png])|


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

m4_cleardivert([DEFAULT])dnl
m4_divert([DEFAULT])dnl


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
m4_traceoff([__LANG_NAME3])dnl
m4_traceon([__PAGE])dnl
dnl m4_traceon([__LOCALIZE_URL_NAME])dnl
dnl m4_traceon([__LOCALIZE_URL_PATH])dnl
dnl m4_traceon([__LOCALIZE_URL_NULL])dnl
---------------------------------------
dnl __PAGE([aaa.com],[en,es],[somepath/main],[__CANONICAL_PAGE__],[__LOCALIZE_URL_PATH])
dnl __PAGE([bbb.com],[en],   [somepath/main],[__ALTERNATE_PAGE__],[__LOCALIZE_URL_PATH])
---------------------------------------
dnl m4_traceoff([__LOCALIZE_URL_NULL])dnl
dnl m4_traceoff([__LOCALIZE_URL_NAME])dnl
m4_traceoff([__PAGE])dnl
DEPEND---------------------------------
m4_undivert([DEPEND])dnl
DEPEND---------------------------------
NAVIGATION-----------------------------
m4_undivert([NAVIGATION])dnl
NAVIGATION-----------------------------

INC_CSS--------------------------------
dnl m4_changequote(«,»)
dnl m4_bregexp([m4_include(/home/rodablo/www/_build/vendor/fontawesome-free-5.13.0-web/css/all.css)],[url\($1\)],[\1])
dnl m4_bregexp([jsflkfjdlskjfurl("roro")sjdlurl("tata")fkjslkdfj],[\(url("\(.+\)")\)],[\1])
dnl m4_changequote([,])
m4_define([__TOTO__],m4_flatten(m4_esyscmd_s([grep -oP '(?<=url\(\").+?(?=\"\))' _build/vendor/fontawesome-free-5.13.0-web/css/all.css])))
INC_CSS--------------------------------
>__TOTO__<
INC_CSS--------------------------------
m4_foreach_w([__L__],[__TOTO__],m4_quote([__L__]))
INC_CSS--------------------------------


